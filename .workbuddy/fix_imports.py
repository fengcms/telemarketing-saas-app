import os, re

pkg = 'telemarketing_app'
lib_dir = os.path.join(os.getcwd(), 'lib')
regex = re.compile(r'''^(import\s+['\"])((?:\.\.?/)+)([^'"]+)(['\"];)\s*$''')

stats = {'changed': 0, 'files': []}

for root, dirs, files in os.walk(lib_dir):
    for f in sorted(files):
        if not f.endswith('.dart'):
            continue
        fpath = os.path.join(root, f)
        frel = os.path.relpath(fpath, lib_dir)
        
        with open(fpath, 'r') as fh:
            content = fh.read()
        
        def replace_rel(m, frel=frel):
            rel = m.group(2)
            target = m.group(3)
            fdir = os.path.dirname(frel)
            combined = os.path.normpath(os.path.join(fdir, rel + target))
            if combined.startswith('..'):
                abs_path = os.path.normpath(os.path.join(lib_dir, combined))
                combined = os.path.relpath(abs_path, lib_dir)
            stats['changed'] += 1
            return f"import 'package:{pkg}/{combined}'"
        
        new_content = regex.sub(replace_rel, content)
        if new_content != content:
            with open(fpath, 'w') as fh:
                fh.write(new_content)
            stats['files'].append(frel)

print(f"{stats['changed']} imports in {len(stats['files'])} files")
for f in sorted(stats['files']):
    print(f'  {f}')
