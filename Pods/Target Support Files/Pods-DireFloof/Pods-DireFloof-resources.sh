#!/bin/sh
set -e

mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt
> "$RESOURCES_TO_COPY"

XCASSET_FILES=()

# This protects against multiple targets copying the same framework dependency at the same time. The solution
# was originally proposed here: https://lists.samba.org/archive/rsync/2008-February/020158.html
RSYNC_PROTECT_TMP_FILES=(--filter "P .*.??????")

case "${TARGETED_DEVICE_FAMILY}" in
  1,2)
    TARGET_DEVICE_ARGS="--target-device ipad --target-device iphone"
    ;;
  1)
    TARGET_DEVICE_ARGS="--target-device iphone"
    ;;
  2)
    TARGET_DEVICE_ARGS="--target-device ipad"
    ;;
  3)
    TARGET_DEVICE_ARGS="--target-device tv"
    ;;
  4)
    TARGET_DEVICE_ARGS="--target-device watch"
    ;;
  *)
    TARGET_DEVICE_ARGS="--target-device mac"
    ;;
esac

install_resource()
{
  if [[ "$1" = /* ]] ; then
    RESOURCE_PATH="$1"
  else
    RESOURCE_PATH="${PODS_ROOT}/$1"
  fi
  if [[ ! -e "$RESOURCE_PATH" ]] ; then
    cat << EOM
error: Resource "$RESOURCE_PATH" not found. Run 'pod install' to update the copy resources script.
EOM
    exit 1
  fi
  case $RESOURCE_PATH in
    *.storyboard)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile ${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .storyboard`.storyboardc $RESOURCE_PATH --sdk ${SDKROOT} ${TARGET_DEVICE_ARGS}" || true
      ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .storyboard`.storyboardc" "$RESOURCE_PATH" --sdk "${SDKROOT}" ${TARGET_DEVICE_ARGS}
      ;;
    *.xib)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile ${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .xib`.nib $RESOURCE_PATH --sdk ${SDKROOT} ${TARGET_DEVICE_ARGS}" || true
      ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .xib`.nib" "$RESOURCE_PATH" --sdk "${SDKROOT}" ${TARGET_DEVICE_ARGS}
      ;;
    *.framework)
      echo "mkdir -p ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}" || true
      mkdir -p "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      echo "rsync --delete -av "${RSYNC_PROTECT_TMP_FILES[@]}" $RESOURCE_PATH ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}" || true
      rsync --delete -av "${RSYNC_PROTECT_TMP_FILES[@]}" "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodel)
      echo "xcrun momc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH"`.mom\"" || true
      xcrun momc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodel`.mom"
      ;;
    *.xcdatamodeld)
      echo "xcrun momc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodeld`.momd\"" || true
      xcrun momc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodeld`.momd"
      ;;
    *.xcmappingmodel)
      echo "xcrun mapc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcmappingmodel`.cdm\"" || true
      xcrun mapc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcmappingmodel`.cdm"
      ;;
    *.xcassets)
      ABSOLUTE_XCASSET_FILE="$RESOURCE_PATH"
      XCASSET_FILES+=("$ABSOLUTE_XCASSET_FILE")
      ;;
    *)
      echo "$RESOURCE_PATH" || true
      echo "$RESOURCE_PATH" >> "$RESOURCES_TO_COPY"
      ;;
  esac
}
if [[ "$CONFIGURATION" == "Debug" ]]; then
  install_resource "${PODS_ROOT}/DateTools/DateTools/DateTools/DateTools.bundle"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMEmptyFolder@1x.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMEmptyFolder@2x.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMSelected.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMSelected@2x.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMVideoIcon.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMVideoIcon@2x.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/Base.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/ca.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/de.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/en.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/es.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/fr.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/it.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/pt.lproj"
  install_resource "${PODS_ROOT}/GPUImage/framework/Resources/lookup.png"
  install_resource "${PODS_ROOT}/GPUImage/framework/Resources/lookup_amatorka.png"
  install_resource "${PODS_ROOT}/GPUImage/framework/Resources/lookup_miss_etikate.png"
  install_resource "${PODS_ROOT}/GPUImage/framework/Resources/lookup_soft_elegance_1.png"
  install_resource "${PODS_ROOT}/GPUImage/framework/Resources/lookup_soft_elegance_2.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/activityMH.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/activtyMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/EditControl.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/EditControl@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/EditControlSelected.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/EditControlSelected@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/error.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/error@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/facebookMH.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/facebookMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/ic_square.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/ic_square@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/left_arrow.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/left_arrow@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/mailMH.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/mailMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/messageMH.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/messageMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/pause.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/pause@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/play.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/play@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/playButton.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/playButton@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/right_arrow.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/right_arrow@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/saveMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/sliderPoint.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/sliderPoint@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/twitterMH.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/twitterMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/unplay.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/unplay@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/videoIcon.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/videoIcon@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/MHGallery.bundle"
  install_resource "${PODS_ROOT}/OAuth2/Pod/Classes/OAuthRequestController.xib"
  install_resource "$PODS_CONFIGURATION_BUILD_DIR/OAuth2/OAuth2.bundle"
fi
if [[ "$CONFIGURATION" == "Release" ]]; then
  install_resource "${PODS_ROOT}/DateTools/DateTools/DateTools/DateTools.bundle"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMEmptyFolder@1x.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMEmptyFolder@2x.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMSelected.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMSelected@2x.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMVideoIcon.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMVideoIcon@2x.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/Base.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/ca.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/de.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/en.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/es.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/fr.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/it.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/pt.lproj"
  install_resource "${PODS_ROOT}/GPUImage/framework/Resources/lookup.png"
  install_resource "${PODS_ROOT}/GPUImage/framework/Resources/lookup_amatorka.png"
  install_resource "${PODS_ROOT}/GPUImage/framework/Resources/lookup_miss_etikate.png"
  install_resource "${PODS_ROOT}/GPUImage/framework/Resources/lookup_soft_elegance_1.png"
  install_resource "${PODS_ROOT}/GPUImage/framework/Resources/lookup_soft_elegance_2.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/activityMH.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/activtyMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/EditControl.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/EditControl@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/EditControlSelected.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/EditControlSelected@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/error.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/error@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/facebookMH.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/facebookMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/ic_square.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/ic_square@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/left_arrow.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/left_arrow@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/mailMH.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/mailMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/messageMH.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/messageMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/pause.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/pause@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/play.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/play@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/playButton.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/playButton@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/right_arrow.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/right_arrow@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/saveMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/sliderPoint.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/sliderPoint@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/twitterMH.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/twitterMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/unplay.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/unplay@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/videoIcon.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/videoIcon@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/MHGallery.bundle"
  install_resource "${PODS_ROOT}/OAuth2/Pod/Classes/OAuthRequestController.xib"
  install_resource "$PODS_CONFIGURATION_BUILD_DIR/OAuth2/OAuth2.bundle"
fi
if [[ "$CONFIGURATION" == "Adhoc" ]]; then
  install_resource "${PODS_ROOT}/DateTools/DateTools/DateTools/DateTools.bundle"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMEmptyFolder@1x.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMEmptyFolder@2x.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMSelected.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMSelected@2x.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMVideoIcon.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/GMVideoIcon@2x.png"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/Base.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/ca.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/de.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/en.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/es.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/fr.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/it.lproj"
  install_resource "${PODS_ROOT}/GMImagePicker/GMImagePicker/pt.lproj"
  install_resource "${PODS_ROOT}/GPUImage/framework/Resources/lookup.png"
  install_resource "${PODS_ROOT}/GPUImage/framework/Resources/lookup_amatorka.png"
  install_resource "${PODS_ROOT}/GPUImage/framework/Resources/lookup_miss_etikate.png"
  install_resource "${PODS_ROOT}/GPUImage/framework/Resources/lookup_soft_elegance_1.png"
  install_resource "${PODS_ROOT}/GPUImage/framework/Resources/lookup_soft_elegance_2.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/activityMH.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/activtyMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/EditControl.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/EditControl@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/EditControlSelected.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/EditControlSelected@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/error.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/error@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/facebookMH.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/facebookMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/ic_square.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/ic_square@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/left_arrow.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/left_arrow@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/mailMH.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/mailMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/messageMH.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/messageMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/pause.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/pause@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/play.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/play@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/playButton.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/playButton@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/right_arrow.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/right_arrow@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/saveMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/sliderPoint.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/sliderPoint@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/twitterMH.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/twitterMH@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/unplay.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/unplay@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/videoIcon.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/Images/videoIcon@2x.png"
  install_resource "${PODS_ROOT}/MHVideoPhotoGallery/MHVideoPhotoGallery/MMHVideoPhotoGallery/MHGallery.bundle"
  install_resource "${PODS_ROOT}/OAuth2/Pod/Classes/OAuthRequestController.xib"
  install_resource "$PODS_CONFIGURATION_BUILD_DIR/OAuth2/OAuth2.bundle"
fi

mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
if [[ "${ACTION}" == "install" ]] && [[ "${SKIP_INSTALL}" == "NO" ]]; then
  mkdir -p "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
rm -f "$RESOURCES_TO_COPY"

if [[ -n "${WRAPPER_EXTENSION}" ]] && [ "`xcrun --find actool`" ] && [ -n "$XCASSET_FILES" ]
then
  # Find all other xcassets (this unfortunately includes those of path pods and other targets).
  OTHER_XCASSETS=$(find "$PWD" -iname "*.xcassets" -type d)
  while read line; do
    if [[ $line != "${PODS_ROOT}*" ]]; then
      XCASSET_FILES+=("$line")
    fi
  done <<<"$OTHER_XCASSETS"

  printf "%s\0" "${XCASSET_FILES[@]}" | xargs -0 xcrun actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${!DEPLOYMENT_TARGET_SETTING_NAME}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
