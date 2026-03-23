"""
files.py — scans a directory and returns recent large files.

This module has no knowledge of config files, Flask, or anything else.
It just takes plain arguments and returns data.
"""

import os
from dataclasses import dataclass
from datetime import datetime


@dataclass
class FileEntry:
    path: str
    name: str
    size_bytes: int
    modified: datetime


def scan_files(downloads_path: str, min_size_mb: int) -> list[FileEntry]:
    """
    Walk downloads_path recursively and return all files larger than
    min_size_mb, sorted by modification date (newest first).

    Args:
        downloads_path: absolute path to the folder to scan
        min_size_mb:    minimum file size in megabytes

    Returns:
        list of FileEntry, newest-modified first
    """
    min_size_bytes = min_size_mb * 1024 * 1024
    results = []

    for dirpath, _dirnames, filenames in os.walk(downloads_path):
        for filename in filenames:
            full_path = os.path.join(dirpath, filename)

            try:
                stat = os.stat(full_path)
            except OSError:
                # File disappeared between the directory listing and the stat
                # call, or we don't have permission. Skip it.
                continue

            if stat.st_size < min_size_bytes:
                continue

            results.append(FileEntry(
                path=full_path,
                name=filename,
                size_bytes=stat.st_size,
                modified=datetime.fromtimestamp(stat.st_mtime),
            ))

    results.sort(key=lambda f: f.modified, reverse=True)
    return results