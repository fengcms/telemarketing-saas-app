#!/usr/bin/env python3
"""Batch move first /// doc block before imports in Dart files."""

import os
import re
import glob

lib_dir = '/Users/fungleo/Sites/ShangHaiYingZhou/telemarketing-saas-app/lib'
exclude_dirs = ['models', 'constants']

for root, dirs, files in os.walk(lib_dir):
    # Skip excluded dirs
    rel = os.path.relpath(root, lib_dir)
    if any(rel.startswith(e) or rel == e for e in exclude_dirs):
        continue

    for fname in files:
        if not fname.endswith('.dart'):
            continue

        fpath = os.path.join(root, fname)

        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read()
            lines = content.split('\n')

        # Skip if file doesn't start with import (already has header)
        if not lines or not lines[0].startswith('import'):
            continue

        # Find first /// block (continuous lines)
        first_doc_start = None
        first_doc_end = None
        for i, line in enumerate(lines):
            if line.startswith('///'):
                first_doc_start = i
                # Find end of this doc block
                j = i
                while j < len(lines) and (lines[j].startswith('///') or lines[j] == ''):
                    j += 1
                first_doc_end = j
                break

        if first_doc_start is None:
            continue  # No doc comment found

        # Extract the doc block
        doc_lines = lines[first_doc_start:first_doc_end]
        # Strip trailing blank lines from doc
        while doc_lines and doc_lines[-1].strip() == '':
            doc_lines.pop()

        # Create file header: doc + library; + blank line
        header = doc_lines + ['library;', '']

        # Rebuild: header + original content
        new_lines = header + lines
        new_content = '\n'.join(new_lines)

        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(new_content)

        print(f"Fixed: {fpath}")

print("Done!")
