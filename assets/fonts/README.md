# Bundled application fonts

These source-controlled fonts make localized rendering and golden tests independent of fonts
installed on a developer or CI host.

| Family | Version/source | SHA-256 | License |
| --- | --- | --- | --- |
| Noto Sans | Generated ForUI theme asset | `NotoSans.ttf` is `7b8cac46a1c86d2533a616b1fcf4e1926b8e39bda69034508b0df96791f56d97`; `NotoSans-Italic.ttf` is `4bf7b366af79c434984d67eae3967e9cd7a2f51c196101c43f21a7e21e608844` | `Noto_Sans/LICENSE.txt` |
| Noto Sans Arabic | [NotoSansArabic v2.013 release](https://github.com/notofonts/arabic/releases/tag/NotoSansArabic-v2.013), static Regular/Medium/SemiBold/Bold TTFs | Regular `7ed3fe069312aceac454f17cf613a30f95271d6ed7ce58005ed4d016bd3823d7`; Medium `23c6d6520915f455585ef796db6897393e486637510dd3b255047f7095a11478`; SemiBold `a1548f8031214d637c2f5fc65c279cba7baf4673ea6f14e81b073ef2f8bae1b7`; Bold `5ccd1a8914f7c7e8aa8050f2c7c37b10fc5e855f06583c2a2248a436aad3fc0f` | `Noto_Sans_Arabic/LICENSE.txt` |
| Noto Sans SC | [Noto CJK Sans 2.004 tagged asset](https://github.com/notofonts/noto-cjk/blob/Sans2.004/Sans/Variable/TTF/Subset/NotoSansSC-VF.ttf) | `d68bafcb48a2707749396aa12bbbd833cb70401f3a9a689fd2902c7e0d295964` | `Noto_Sans_SC/LICENSE.txt` |

Verify the committed assets with:

```sh
shasum -a 256 \
  assets/fonts/Noto_Sans/NotoSans.ttf \
  assets/fonts/Noto_Sans_Arabic/*.ttf \
  assets/fonts/Noto_Sans_SC/NotoSansSC.ttf
```
