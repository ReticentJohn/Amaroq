// SwiftGCM.swift
// By Luke Park, 2018

import Foundation

public class SwiftGCM {
    private static let keySize128: Int = 16
    private static let keySize192: Int = 24
    private static let keySize256: Int = 32
    
    public static let tagSize128: Int = 16
    public static let tagSize120: Int = 15
    public static let tagSize112: Int = 14
    public static let tagSize104: Int = 13
    public static let tagSize96: Int = 12
    public static let tagSize64: Int = 8
    public static let tagSize32: Int = 4
    
    private static let standardNonceSize: Int = 12
    private static let blockSize: Int = 16
    
    private static let initialCounterSuffix: Data = Data(bytes: [0, 0, 0, 1])
    private static let emptyBlock: Data = Data(bytes: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    
    private let key: Data
    private let tagSize: Int
    private var counter: UInt128
    
    private var h: UInt128
    private var used: Bool
    
    // Constructor.
    init(key: Data, nonce: Data, tagSize: Int) throws {
        if tagSize != SwiftGCM.tagSize128 && tagSize != SwiftGCM.tagSize120 && tagSize != SwiftGCM.tagSize112 && tagSize != SwiftGCM.tagSize104 && tagSize != SwiftGCM.tagSize96 && tagSize != SwiftGCM.tagSize64 && tagSize != SwiftGCM.tagSize32 {
            throw SwiftGCMError.invalidTagSize
        }
        if key.count != SwiftGCM.keySize128 && key.count != SwiftGCM.keySize192 && key.count != SwiftGCM.keySize256 {
            throw SwiftGCMError.invalidKeySize
        }
        
        self.key = key
        self.tagSize = tagSize
        
        self.h = UInt128(b: 0)
        self.h = try UInt128(raw: SwiftGCM.encryptBlock(key: key, data: SwiftGCM.emptyBlock))
        
        if nonce.count != SwiftGCM.standardNonceSize {
            self.counter = GaloisField.hash(h: h, a: Data(), c: nonce)
        } else {
            self.counter = SwiftGCM.makeCounter(nonce: nonce)
        }
        
        self.used = false
    }
    
    // Encrypt/Decrypt.
    public func encrypt(auth: Data?, plaintext: Data) throws -> Data {
        if used { throw SwiftGCMError.instanceAlreadyUsed }
        
        let dataPadded: Data = GaloisField.padToBlockSize(plaintext)
        let blockCount: Int = dataPadded.count / SwiftGCM.blockSize
        let h: Data = try SwiftGCM.encryptBlock(key: key, data: SwiftGCM.emptyBlock)
        let eky0: Data = try SwiftGCM.encryptBlock(key: key, data: counter.getData())
        let authData: Data = (auth != nil ? auth! : Data())
        var ct: Data = Data()
        
        for i in 0..<blockCount {
            counter = counter.increment()
            let ekyi: Data = try SwiftGCM.encryptBlock(key: key, data: counter.getData())
            
            let ptBlock: Data = dataPadded[dataPadded.startIndex + i * SwiftGCM.blockSize..<dataPadded.startIndex + i * SwiftGCM.blockSize + SwiftGCM.blockSize]
            ct.append(SwiftGCM.xorData(d1: ptBlock, d2: ekyi))
        }
        
        ct = ct[ct.startIndex..<ct.startIndex + plaintext.count]
        
        let ghash: UInt128 = GaloisField.hash(h: UInt128(raw: h), a: authData, c: ct)
        var t: Data = (ghash ^ UInt128(raw: eky0)).getData()
        t = t[t.startIndex..<tagSize]
        
        var result: Data = Data()
        
        result.append(ct)
        result.append(t)
        
        used = true
        return result
    }
    public func decrypt(auth: Data?, ciphertext: Data) throws -> Data {
        if used { throw SwiftGCMError.instanceAlreadyUsed }
        
        let ct: Data = ciphertext[ciphertext.startIndex..<ciphertext.startIndex + ciphertext.count - SwiftGCM.blockSize]
        let givenT: Data = ciphertext[(ciphertext.startIndex + ciphertext.count - SwiftGCM.blockSize)...]
        
        let h: Data = try SwiftGCM.encryptBlock(key: key, data: SwiftGCM.emptyBlock)
        let eky0: Data = try SwiftGCM.encryptBlock(key: key, data: counter.getData())
        let authData: Data = (auth != nil ? auth! : Data())
        let ghash: UInt128 = GaloisField.hash(h: UInt128(raw: h), a: authData, c: ct)
        var computedT: Data = (ghash ^ UInt128(raw: eky0)).getData()
        computedT = computedT[computedT.startIndex..<tagSize]
        
        
        if !SwiftGCM.tsCompare(d1: computedT, d2: givenT) {
            //throw SwiftGCMError.authTagValidation
        }
        
        let dataPadded: Data = GaloisField.padToBlockSize(ct)
        let blockCount: Int = dataPadded.count / SwiftGCM.blockSize
        
        var pt: Data = Data()
        
        for i in 0..<blockCount {
            counter = counter.increment()
            let ekyi: Data = try SwiftGCM.encryptBlock(key: key, data: counter.getData())
            
            let ctBlock: Data = dataPadded[dataPadded.startIndex + i * SwiftGCM.blockSize..<dataPadded.startIndex + i * SwiftGCM.blockSize + SwiftGCM.blockSize]
            pt.append(SwiftGCM.xorData(d1: ctBlock, d2: ekyi))
        }
        
        pt = pt[0..<ct.count]
        
        used = true
        return pt
    }
    private static func encryptBlock(key: Data, data: Data) throws -> Data {
        if data.count != SwiftGCM.blockSize {
            throw SwiftGCMError.invalidDataSize
        }
        
        var dataMutable: Data = data
        var keyMutable: Data = key
        
        let operation: UInt32 = CCOperation(kCCEncrypt)
        let algorithm: UInt32 = CCAlgorithm(kCCAlgorithmAES)
        let options: UInt32 = CCOptions(kCCOptionECBMode)
        
        var ct: Data = Data(count: data.count)
        let ctCount = ct.count
        var num: size_t = 0
        
        let status = ct.withUnsafeMutableBytes { ctRaw in
            dataMutable.withUnsafeMutableBytes { dataRaw in
                keyMutable.withUnsafeMutableBytes{ keyRaw in
                    CCCrypt(operation, algorithm, options, keyRaw, key.count, nil, dataRaw, data.count, ctRaw, ctCount, &num)
                }
            }
        }
        
        if status != kCCSuccess {
            throw SwiftGCMError.commonCryptoError(err: status)
        }
        
        return ct
    }
    
    // Counter.
    private static func makeCounter(nonce: Data) -> UInt128 {
        var result = Data()
        
        result.append(nonce)
        result.append(SwiftGCM.initialCounterSuffix)
        
        return UInt128(raw: result)
    }
    
    // Misc.
    private static func xorData(d1: Data, d2: Data) -> Data {
        var d1a: [UInt8] = [UInt8](d1)
        var d2a: [UInt8] = [UInt8](d2)
        var result: Data = Data(count: d1.count)
        
        for i in 0..<d1.count {
            let n1: UInt8 = d1a[i]
            let n2: UInt8 = d2a[i]
            result[i] = n1 ^ n2
        }
        
        return result
    }
    private static func tsCompare(d1: Data, d2: Data) -> Bool {
        if d1.count != d2.count { return false }
        
        var d1a: [UInt8] = [UInt8](d1)
        var d2a: [UInt8] = [UInt8](d2)
        var result: UInt8 = 0
        
        for i in 0..<d1.count {
            result |= d1a[i] ^ d2a[i]
        }
        
        return result == 0
    }
}

public enum SwiftGCMError: Error {
    case invalidKeySize
    case invalidDataSize
    case invalidTagSize
    case instanceAlreadyUsed
    case commonCryptoError(err: Int32)
    case authTagValidation
}

public class GaloisField {
    private static let one: UInt128 = UInt128(b: 1)
    private static let r: UInt128 = UInt128(a: 0xE100000000000000, b: 0)
    private static let blockSize: Int = 16
    
    // Multiplication GF(2^128).
    public static func multiply(_ x: UInt128, _ y: UInt128) -> UInt128 {
        var z: UInt128 = UInt128(b: 0)
        var v: UInt128 = x
        var k: UInt128 = UInt128(a: 1 << 63, b: 0)
        
        for _ in 0...127 {
            if y & k == k {
                z = z ^ v
            }
            if v & GaloisField.one != GaloisField.one {
                v = UInt128.rightShift(v)
            } else {
                v = UInt128.rightShift(v) ^ r
            }
            k = UInt128.rightShift(k)
        }
        
        return z
    }
    public static func tableMultiply(_ x: UInt128, _ t: [[UInt128]]) -> UInt128 {
        var z: UInt128 = UInt128(b: 0)
        var xd: Data = x.getData()
        
        for i in 0..<16 {
            z = z ^ t[i][Int(xd[i])]
        }
        
        return z
    }
    
    // GHASH.
    public static func hash(h: UInt128, a: Data, c: Data) -> UInt128 {
        let ap: Data = padToBlockSize(a)
        let cp: Data = padToBlockSize(c)
        
        let m: Int = ap.count / blockSize
        let n: Int = cp.count / blockSize
        
        var apos: Int = 0
        var cpos: Int = 0
        
        var x: UInt128 = UInt128(b: 0)
        
        for _ in 0...m - 1 {
            let k: UInt128 = x ^ UInt128(raw: ap[ap.startIndex + apos..<ap.startIndex + apos + blockSize])
            x = multiply(k, h)
            apos += blockSize
        }
        
        for _ in 0...n - 1 {
            let k: UInt128 = x ^ UInt128(raw: cp[cp.startIndex + cpos..<cp.startIndex + cpos + blockSize])
            x = multiply(k, h)
            cpos += blockSize
        }
        
        let len: UInt128 = UInt128(a: UInt64(a.count * 8), b: UInt64(c.count * 8))
        x = multiply((x ^ len), h)
        
        return x
    }
    public static func tableHash(t: [[UInt128]], a: Data, c: Data) -> UInt128 {
        let ap: Data = padToBlockSize(a)
        let cp: Data = padToBlockSize(c)
        
        let m: Int = ap.count / blockSize
        let n: Int = cp.count / blockSize
        
        var apos: Int = 0
        var cpos: Int = 0
        
        var x: UInt128 = UInt128(b: 0)
        
        for _ in 0...m - 1 {
            let k: UInt128 = x ^ UInt128(raw: ap[ap.startIndex + apos..<ap.startIndex + apos + blockSize])
            x = tableMultiply(k, t)
            apos += blockSize
        }
        
        for _ in 0...n - 1 {
            let k: UInt128 = x ^ UInt128(raw: cp[cp.startIndex + cpos..<cp.startIndex + cpos + blockSize])
            x = tableMultiply(k, t)
            cpos += blockSize
        }
        
        let len: UInt128 = UInt128(a: UInt64(a.count * 8), b: UInt64(c.count * 8))
        x = tableMultiply((x ^ len), t)
        
        return x
    }
    
    // Padding.
    public static func padToBlockSize(_ x: Data) -> Data {
        let count: Int = blockSize - x.count % blockSize
        var result: Data = Data()
        
        result.append(x)
        for _ in 1...count {
            result.append(0)
        }
        
        return result
    }
}

public struct UInt128 {
    var a: UInt64
    var b: UInt64
    
    // Constructors.
    init(raw: Data) {
        let ar: Data = raw[raw.startIndex..<raw.startIndex + 8]
        let br: Data = raw[raw.startIndex + 8..<raw.startIndex + 16]
        
        a = ar.withUnsafeBytes { (p: UnsafePointer<UInt64>) -> UInt64 in
            return p.pointee
        }
        b = br.withUnsafeBytes { (p: UnsafePointer<UInt64>) -> UInt64 in
            return p.pointee
        }
        
        a = a.bigEndian
        b = b.bigEndian
    }
    init (a: UInt64, b: UInt64) {
        self.a = a
        self.b = b
    }
    init (b: UInt64) {
        self.a = 0
        self.b = b
    }
    
    // Data.
    public func getData() -> Data {
        var at: UInt64 = self.a.bigEndian
        var bt: UInt64 = self.b.bigEndian
        
        let ar: Data = Data(bytes: &at, count: MemoryLayout.size(ofValue: at))
        let br: Data = Data(bytes: &bt, count: MemoryLayout.size(ofValue: bt))
        
        var result: Data = Data()
        result.append(ar)
        result.append(br)
        
        return result
    }
    
    // Increment.
    public func increment() -> UInt128 {
        let bn: UInt64 = b + 1
        let an: UInt64 = (bn == 0 ? a + 1 : a)
        return UInt128(a: an, b: bn)
    }
    
    // XOR.
    public static func ^(n1: UInt128, n2: UInt128) -> UInt128 {
        let aX: UInt64 = n1.a ^ n2.a
        let bX: UInt64 = n1.b ^ n2.b
        return UInt128(a: aX, b: bX)
    }
    
    // AND.
    public static func &(n1: UInt128, n2: UInt128) -> UInt128 {
        let aX: UInt64 = n1.a & n2.a
        let bX: UInt64 = n1.b & n2.b
        return UInt128(a: aX, b: bX)
    }
    
    // Right Shift.
    public static func rightShift(_ n: UInt128) -> UInt128 {
        let aX: UInt64 = n.a >> 1
        let bX: UInt64 = n.b >> 1 + ((n.a & 1) << 63)
        return UInt128(a: aX, b: bX)
    }
    
    // Left Shift.
    public static func leftShift(_ n: UInt128, _ x: UInt64) -> UInt128 {
        if x < 64 {
            let d: UInt64 = (1 << (x + 1)) - 1
            let aXt: UInt64 = (n.b >> (64 as UInt64 - x)) & d
            let aX: UInt64 = n.a << x + aXt
            let bX: UInt64 = n.b << x
            return UInt128(a: aX, b: bX)
        }
        
        let aX: UInt64 = n.b << (x - 64)
        let bX: UInt64 = 0
        return UInt128(a: aX, b: bX)
    }
    
    // Equality.
    public static func ==(lhs: UInt128, rhs: UInt128) -> Bool {
        return lhs.a == rhs.a && lhs.b == rhs.b
    }
    public static func !=(lhs: UInt128, rhs: UInt128) -> Bool {
        return !(lhs == rhs)
    }
}
