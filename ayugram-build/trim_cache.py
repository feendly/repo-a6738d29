#!/usr/bin/env python3
"""Keeps the Bazel disk cache under a size limit by removing the least recently written entries.

Usage: trim_cache.py <cache directory> <limit in GB>

Every CI run restores the cache and adds its own outputs, so without this it only grows
until the hosted runner's disk is full (run 45281272522). Bazel refreshes the modification
time of an entry when it is used, so the oldest entries are the ones no recent build needed.
"""
import os
import sys


def main():
    root = sys.argv[1]
    limit = float(sys.argv[2]) * 1024 ** 3
    files = []
    for directory, _, names in os.walk(root):
        for name in names:
            path = os.path.join(directory, name)
            try:
                info = os.lstat(path)
            except OSError:
                continue
            files.append((info.st_mtime, info.st_size, path))
    total = sum(size for _, size, _ in files)
    print("cache before: %.2f GB in %d files" % (total / 1024 ** 3, len(files)))
    files.sort()
    removed = 0
    for _, size, path in files:
        if total <= limit:
            break
        try:
            os.remove(path)
        except OSError:
            continue
        total -= size
        removed += 1
    print("cache after: %.2f GB, removed %d files" % (total / 1024 ** 3, removed))


if __name__ == "__main__":
    main()
