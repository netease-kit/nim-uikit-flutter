# nim_chatkit_sticker

`nim_chatkit_sticker` is an optional Sticker extension for
`nim_chatkit_ui`. It keeps the default Sticker resources out of the base chat
UIKit and sends every Sticker through the existing image-message flow.

## Default Integration

Add the package beside `nim_chatkit_ui`, then initialize it after
`ChatKitClient`:

```dart
ChatKitClient.init();
StickerKitClient.init();
```

Add `StickerKitClient.delegate` to the host App's
`localizationsDelegates`. The package includes `ajmd`, `lt`, and `xxy` by
default.

## Disable Sticker

```dart
StickerKitClient.init(
  config: const StickerConfig(enabled: false),
);
```

The configuration is read during initialization. Disabling the extension does
not affect image messages already sent or received.

## Replace With App Assets

Declare the assets in the customer App's `pubspec.yaml`. Keep `packageName`
null so Flutter loads them from the App bundle:

```dart
final customPack = StickerPack(
  id: 'customer',
  tabIcon: const StickerAssetSource(
    assetPath: 'assets/stickers/customer_normal.png',
  ),
  selectedTabIcon: const StickerAssetSource(
    assetPath: 'assets/stickers/customer_selected.png',
  ),
  stickers: const <StickerItem>[
    StickerItem(
      id: 'customer_001',
      image: StickerAssetSource(
        assetPath: 'assets/stickers/customer_001.png',
      ),
    ),
  ],
);

StickerKitClient.init(
  config: StickerConfig(packs: <StickerPack>[customPack]),
);
```

## Use Another Resource Package

Set `packageName` on each `StickerAssetSource` to the package that declares the
asset. This works with a published `nim_chatkit_sticker` dependency and does
not require modifying its source.

```dart
const source = StickerAssetSource(
  assetPath: 'assets/stickers/company_001.png',
  packageName: 'company_sticker_assets',
);
```

To append instead of replace, combine the defaults with the custom pack:

```dart
StickerKitClient.init(
  config: StickerConfig(
    packs: <StickerPack>[
      ...StickerDefaults.packs,
      customPack,
    ],
  ),
);
```
