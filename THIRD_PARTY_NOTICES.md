# Third-party notices

Dejunk-WotLK is an independent compatibility port, not an official release of
Dejunk or a Blizzard product. Names and attribution do not imply endorsement.

| Component | Creator / source | License | Distribution |
|---|---|---|---|
| Dejunk reference and inherited notices | [moody/Dejunk](https://github.com/moody/Dejunk), commit `04bafd5e411441ef5b51bb8ed10d208f2d7758f5` | [MIT](https://github.com/moody/Dejunk/blob/04bafd5e411441ef5b51bb8ed10d208f2d7758f5/LICENSE) | Upstream artwork and Waffle are redistributed; the compatibility modules are independently implemented |
| Waffle 0.12.2 | [moody/Waffle](https://github.com/moody/Waffle), vendored from the pinned Dejunk snapshot | MIT | `libs/Waffle.lua`; full notice in [Waffle-LICENSE.txt](libs/Waffle-LICENSE.txt) |
| Cash / Dejunk logo | [Cash by Lorc](https://game-icons.net/1x1/lorc/cash.html) · [creator](https://lorcblog.blogspot.com/) | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) | `assets/dejunk-icon.tga` |
| UI action icons | [Font Awesome / Fonticons, Inc.](https://fontawesome.com/) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) | Other TGA artwork in `assets/` |

Artwork files are copied unchanged from the pinned upstream snapshot; the port
makes no additional artwork modifications. Their upstream preparation/adaptation
is inherited. Full artwork attribution, source links and license links travel
with every addon ZIP in [assets/LICENSE.txt](assets/LICENSE.txt).

The Waffle source checksum is
`bd668fb59160f4f9bc4b2b13298c7ca93cbad9be017892b21eac089a3015d396`.
Immutable source and artwork checksums are recorded in
[source-manifest.json](docs/research/source-manifest.json).

Blizzard FrameXML was consulted for compatibility research. No Blizzard client,
FrameXML source, personal SavedVariables or account data is distributed in the
addon package. Blizzard texture paths reference assets supplied by the user's
installed game client.
