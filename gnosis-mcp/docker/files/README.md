# docker/files/

Place the gnosis-mcp wheel file here before building the Docker image.

## Required

Download from PyPI (internet-connected machine):

    https://pypi.org/project/gnosis-mcp/#files

Pick the file matching:
- Python: cp311 (Python 3.11)
- Platform: linux_x86_64 (or none-any if available)

Example filename:
    gnosis_mcp-0.13.3-py3-none-any.whl

## How to download (browser, no installs needed)

1. Go to https://pypi.org/project/gnosis-mcp/#files
2. Click the `.whl` file to download
3. Place it in this directory
4. Build the image: `docker build -t gnosis-mcp-image .`

## Why only this wheel?

All other dependencies (mcp, click, aiofiles, anyio, starlette, httpx)
are available in Artifactory and resolve automatically via pip during build.
Only gnosis-mcp itself is missing from Artifactory.

## This file

This README.md is here to ensure the docker/files/ directory is tracked
by git. The actual .whl file should NOT be committed to the repo.
Add it to .gitignore:

    docker/files/*.whl
