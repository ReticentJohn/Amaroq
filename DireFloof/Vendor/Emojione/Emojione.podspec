Pod::Spec.new do |s|
  name = "EmojiOne"
  version = "2.2.7"

  s.name = name
  s.version = version
  s.license = { :type => "MIT", :text => <<-LICENSE
The MIT License (MIT)

Copyright (c) 2017 EmojiOne

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
LICENSE
 }
  s.summary = "To standardize emoji on the web through the use of common :shortnames:."
  s.homepage = "http://www.emojione.com/"
  s.source = { :git => 'https://github.com/ReticentJohn/emojione.git' }
  s.source_files = "lib/ios/src/*.{h,m}"
  s.author = "EmojiOne"
  s.platform = :ios
end
