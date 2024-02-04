#!/usr/bin/env python3

import glob
import itertools
import json
import re
import subprocess
from collections import OrderedDict
from os import path

MAKEDEPEND = 'makedepend'

def strip_ext(name):
    pos = name.rfind('.')
    return name if pos < 0 else name[:pos]

def chunk(iterator, size):
    iterator = iter(iterator)
    return iter(lambda: tuple(itertools.islice(iterator, size)), ())

with open('config.json', 'rt') as f:
    global_config = json.load(f, object_pairs_hook=OrderedDict)

package_configs = {}
for config_file in glob.glob('*/config.json'):
    with open(config_file, 'rt') as f:
        package_configs[path.dirname(config_file)] = json.load(f, object_pairs_hook=OrderedDict)

targets = OrderedDict()
packages = OrderedDict()
blobs = OrderedDict()
sources = set()

targets[global_config['main_target']] = set()

for (dir, config) in package_configs.items():
    config['base_vertex_shaders'] = [*config['vertex_shaders']]
    config['base_pixel_shaders'] = [*config['pixel_shaders']]
    for shader_config in itertools.chain(config['vertex_shaders'].values(), config['pixel_shaders'].values()):
        sources.add(path.normpath(path.join(dir, shader_config['source'])))
        if 'defines' not in shader_config:
            shader_config['defines'] = []
        if 'defines' in config:
            shader_config['defines'].extend(config['defines'])
    for (package, package_config) in config['packages'].items():
        if 'targets' in package_config:
            for target in package_config['targets']:
                targets.setdefault(target, set())
                targets[target].add(path.normpath(path.join('build', package)))
        package_out = {
            'original': path.normpath(path.join(dir, config['original'])),
            'blob_directory': path.normpath(path.join('build', dir)),
            'parameters': [
                (param, param_config['start'], param_config['size'])
                for (param, param_config)
                in package_config['parameters'].items()
            ] if 'parameters' in package_config else [],
            'keys': [],
            'constants': [*package_config['consants'].items()] if 'consants' in package_config else [],
            'samplers': [*package_config['samplers'].items()] if 'samplers' in package_config else [],
            'uavs': [*package_config['uavs'].items()] if 'uavs' in package_config else [],
            'vertex_shaders': [(-1, shader) for shader in config['base_vertex_shaders']],
            'pixel_shaders': [(-1, shader) for shader in config['base_pixel_shaders']],
        }
        if 'keys' in package_config:
            for key in package_config['keys']:
                key_config = [*config['keys'][key].items()]
                (default, default_config) = key_config[0]
                default_define = default_config['define']
                if not any(default_define in shader_config['defines'] for shader_config in itertools.chain(config['vertex_shaders'].values(), config['pixel_shaders'].values())):
                    continue
                key_out = [key, default]
                for (value, value_config) in key_config[1:]:
                    value_out = [value]
                    value_define = value_config['define']
                    value_suffix = value_config['suffix']
                    for (shader, shader_config) in [*config['vertex_shaders'].items()]:
                        if default_define in shader_config['defines']:
                            index = next((i for (i, sh) in enumerate(package_out['vertex_shaders']) if sh[1] == shader), -1)
                            new_shader_config = shader_config.copy()
                            new_shader_config['defines'] = [
                                value_define if define == default_define else define
                                for define in shader_config['defines']
                            ]
                            config['vertex_shaders'][shader + value_suffix] = new_shader_config
                            value_out.append('vs%d/%d' % (len(package_out['vertex_shaders']), index))
                            package_out['vertex_shaders'].append((index, shader + value_suffix))
                    for (shader, shader_config) in [*config['pixel_shaders'].items()]:
                        if default_define in shader_config['defines']:
                            index = next((i for (i, sh) in enumerate(package_out['pixel_shaders']) if sh[1] == shader), -1)
                            new_shader_config = shader_config.copy()
                            new_shader_config['defines'] = [
                                value_define if define == default_define else define
                                for define in shader_config['defines']
                            ]
                            config['pixel_shaders'][shader + value_suffix] = new_shader_config
                            value_out.append('ps%d/%d' % (len(package_out['pixel_shaders']), index))
                            package_out['pixel_shaders'].append((index, shader + value_suffix))
                    key_out.append(','.join(value_out))
                package_out['keys'].append(key_out)
        packages[path.normpath(path.join('build', package))] = package_out
    for (shader, shader_config) in config['vertex_shaders'].items():
        blobs[path.normpath(path.join('build', dir, shader + '.dxbc'))] = {
            'source': path.normpath(path.join(dir, shader_config['source'])),
            'target': 'vs_' + global_config['shader_model'],
            'defines': shader_config['defines'],
        }
    for (shader, shader_config) in config['pixel_shaders'].items():
        blobs[path.normpath(path.join('build', dir, shader + '.dxbc'))] = {
            'source': path.normpath(path.join(dir, shader_config['source'])),
            'target': 'ps_' + global_config['shader_model'],
            'defines': shader_config['defines'],
        }

source_deps = {strip_ext(src): set() for src in sources}
dependencies = subprocess.run([MAKEDEPEND, '-f', '-', '-Y', *('-I' + dir for dir in global_config['include_paths']), '--', *sources], capture_output=True, text=True, check=True)
depend_line = re.compile(r'^(.*?)\.o: (.*)$', re.MULTILINE | re.IGNORECASE)
for line in depend_line.finditer(dependencies.stdout):
    source_deps[line.group(1)].update(line.group(2).split(' '))

with open('Makefile', 'wt') as f:
    print("""# This file is auto-generated. Do not edit it manually, see configure.py instead.

ifeq ($(OS),Windows_NT)
\tENSURE_TARGET_DIR = if not exist "$(subst /,\,$(@D))" mkdir "$(subst /,\,$(@D))"
\tRM_R := RMDIR /S /Q
\tPATH_SEP := \$ #
else
\tENSURE_TARGET_DIR = mkdir -p $(@D)
\tRM_R := rm -r
\tPATH_SEP := /
endif
""", file=f)
    for (target, target_pkgs) in targets.items():
        print('%s: \\' % (target,), file=f)
        pkgs_list = [*target_pkgs]
        pkgs_list.sort()
        for package in pkgs_list[:-1]:
            print('\t\t%s \\' % (package,), file=f)
        print('\t\t%s' % (pkgs_list[-1],), file=f)
        print(file=f)
    for (package, package_config) in packages.items():
        pkg_deps = [
            *chunk((
                path.normpath(path.join(package_config['blob_directory'], shader[1] + '.dxbc'))
                for shader in itertools.chain(package_config['vertex_shaders'], package_config['pixel_shaders'])
            ), 2),
        ]
        pkg_args = [
            *(('mp+', '%s:%s:%d' % param) for param in package_config['parameters']),
            *(('mk+', ':'.join(key)) for key in package_config['keys']),
            *(('ct=', '%s:%d' % res) for res in package_config['constants']),
            *(('st=', '%s:%d' % res) for res in package_config['samplers']),
            *(('ut=', '%s:%d' % res) for res in package_config['uavs']),
            *(
                ('vs%d/%d' % (i, shader[0]) if shader[0] >= 0 else 'vs%d' % (i,), path.normpath(path.join(package_config['blob_directory'], shader[1] + '.dxbc')))
                for (i, shader) in enumerate(package_config['vertex_shaders'])
            ),
            *(
                ('ps%d/%d' % (i, shader[0]) if shader[0] >= 0 else 'ps%d' % (i,), path.normpath(path.join(package_config['blob_directory'], shader[1] + '.dxbc')))
                for (i, shader) in enumerate(package_config['pixel_shaders'])
            ),
        ]
        print('%s: %s \\' % (package, package_config['original']), file=f)
        for deps in pkg_deps[:-1]:
            print('\t\t%s \\' % (' '.join(deps),), file=f)
        print('\t\t%s' % (' '.join(pkg_deps[-1]),), file=f)
        print('\t%s update $< $@ \\' % (global_config['shpk_tool'],), file=f)
        print('\t\twith pre-disasm \\', file=f)
        for args in pkg_args[:-1]:
            print('\t\t%s \\' % (' '.join(args),), file=f)
        print('\t\t%s' % (' '.join(pkg_args[-1]),), file=f)
        print(file=f)
    for (blob, blob_config) in blobs.items():
        print('%s: %s %s' % (blob, blob_config['source'], ' '.join(source_deps[strip_ext(blob_config['source'])])), file=f)
        print('\t@$(ENSURE_TARGET_DIR)', file=f)
        print('\t%s /T %s %s%s $< /Fo $@ /Fc %s' % (global_config['fxc_exec'], blob_config['target'], global_config['fxc_flags'], ''.join([
            *(' /I%s' % (dir,) for dir in global_config['include_paths']),
            *(' /D%s' % (define,) for define in blob_config['defines']),
        ]), strip_ext(blob) + '.S'), file=f)
        print(file=f)
    print('clean:', file=f)
    for dir in package_configs:
        print('\t-$(RM_R) build$(PATH_SEP)%s' % (dir,), file=f)
    print(file=f)
    print('mrproper: clean', file=f)
    print('\t-$(RM_R) build', file=f)
    print(file=f)
    print('.PHONY: %s clean mrproper' % (' '.join(targets),), file=f)
