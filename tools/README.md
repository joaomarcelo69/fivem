Tools to encode (minify/strip comments) custom resources.

- encode_resources.py: copies resources/pt-* to dist-resources/ with comments stripped and assets minified.
- Intended to reduce readability; not bulletproof obfuscation.

Usage:
1) Run: ./tools/encode_resources.py
2) Point server.cfg to use ensure from dist-resources instead of resources for pt-* resources.
