#!/usr/bin/env python3

import os
import re
import sys

structs = {}
cbuffers = {}
samplers = {}

NAME = re.compile('^[A-Za-z_][A-Za-z0-9_]*')
SAMPLER = re.compile('^Texture([^<]+)<float(\d)>\s+([A-Za-z_][A-Za-z0-9_]*)')
PACKAGE_NAME = re.compile('^(.*)_\d+\.[pv]s\.hlsl$')

class DefCollector:
    def __init__(self, path: str):
        package_name = PACKAGE_NAME.match(os.path.basename(path))
        self.package = package_name.group(1) if package_name is not None else None
        self.path = path
        self.next_cursor = 0
        self.last_line = None
        self.last_cbuffer = None
        self.last_sampler = None
        with open(path, 'rt') as f:
            self.lines = f.readlines()
    def next_line(self):
        line = self.lines[self.next_cursor].strip()
        self.next_cursor += 1
        self.last_line = line
        return line
    def next(self):
        line = self.next_line()
        if line.startswith('cbuffer '):
            cbuf_name = line[8:]
            if ':' in cbuf_name:
                cbuf_name = cbuf_name[:cbuf_name.index(':')]
            cbuf_name = cbuf_name.strip()
            (body, trailer) = self.next_block()
            if trailer != '':
                raise RuntimeError('unexpected cbuffer trailer "%s"' % (trailer,))
            body = '\n'.join(body)
            if cbuf_name in cbuffers:
                if body in cbuffers[cbuf_name]['bodies']:
                    cbuffers[cbuf_name]['bodies'][body].add(self.package)
                else:
                    cbuffers[cbuf_name]['bodies'][body] = set([self.package])
                if self.last_cbuffer is not None:
                    cbuffers[cbuf_name]['previous'].add(self.last_cbuffer)
            else:
                cbuffers[cbuf_name] = {
                    'bodies': {body: set([self.package])},
                    'previous': set([self.last_cbuffer] if self.last_cbuffer is not None else []),
                }
            self.last_cbuffer = cbuf_name
            return line + ';'
        if line == 'struct':
            (body, trailer) = self.next_block()
            var_name = NAME.match(trailer)
            if var_name is None:
                raise RuntimeError('cannot determine variable name in struct trailer "%s"' % (trailer,))
            var_name = var_name.group(0)
            st_name = var_name
            if st_name.startswith('g_') or st_name.startswith('m_'):
                st_name = st_name[2:]
            body = '\n'.join(body)
            st_i = 0
            while True:
                st_i += 1
                st_full_name = (st_name + str(st_i)) if st_i > 1 else st_name
                if st_full_name in structs:
                    if structs[st_full_name]['body'] != body:
                        continue
                else:
                    structs[st_full_name] = {
                        'body': body,
                        'first_seen': self.path,
                    }
                return "%s %s" % (st_full_name, trailer)
        if line.startswith('struct '):
            raise RuntimeError('unexpected named struct')
        if line.startswith('Texture'):
            sampler = SAMPLER.match(line)
            if sampler is not None:
                samp_type = 'GameSampler%s%s' % (sampler.group(1), sampler.group(2))
                samp_name = sampler.group(3)
                if samp_name in samplers:
                    if samp_type in samplers[samp_name]['types']:
                        samplers[samp_name]['types'][samp_type].add(self.package)
                    else:
                        samplers[samp_name]['types'][samp_type] = set([self.package])
                    if self.last_sampler is not None:
                        samplers[samp_name]['previous'].add(self.last_sampler)
                else:
                    samplers[samp_name] = {
                        'types': {samp_type: set([self.package])},
                        'previous': set([self.last_sampler] if self.last_sampler is not None else []),
                    }
                self.last_sampler = samp_name
                return '%s %s;' % (samp_type, samp_name)
        return line
    def next_block(self):
        if self.next_line() != '{':
            raise RuntimeError('unexpected "%s" at block beginning' % (self.last_line,))
        block = []
        while True:
            item = self.next()
            if item.startswith('}'):
                break
            if item != '':
                block.append(item)
        return (block, item[1:].strip())
    def all(self):
        while self.next_cursor < len(self.lines):
            self.next()

for arg in sys.argv[1:]:
    for dir, _, files in os.walk(arg):
        #if 'ui' in dir or 'light' in dir or 'shadow' in dir:
        #    continue
        for file in files:
            full_file = os.path.join(dir, file)
            #if 'ui' in full_file or 'light' in full_file or 'river' in full_file or 'water' in full_file or 'verticalfog' in full_file:
            #    continue
            DefCollector(full_file).all()

def pomap_get(pomap):
    if len(pomap) == 0:
        raise RuntimeError('no item to extract from partially ordered map, empty')
    firsts = {}
    for k, v in pomap.items():
        if len(v['previous']) == 0:
            firsts[k] = v
    if len(firsts) == 0:
        path = [k]
        while True:
            k = next(pomap[k]['previous'].__iter__())
            if k in path:
                path = path[path.index(k):]
                break
            path.append(k)
        raise RuntimeError('no item to extract from partially ordered map, cycle found: %s -> %s' % (' -> '.join(path), path[0]))
    for k in firsts:
        del pomap[k]
        for v in pomap.values():
            if 'orig_previous' not in v:
                v['orig_previous'] = v['previous'].copy()
            v['previous'].discard(k)
    return firsts

def indent(block: str) -> str:
    return '\t' + block.replace('\n', '\n\t')

samplers['g_SamplerViewPosition']['previous'].discard('g_SamplerGBuffer')
samplers['g_SamplerViewPosition']['previous'].discard('g_SamplerGBuffer3')
samplers['g_SamplerVPosition']['previous'].discard('g_SamplerRefractionMap')
samplers['g_SamplerLightDiffuse']['previous'].discard('g_SamplerSpecularMap')
samplers['g_SamplerLightDiffuse']['previous'].discard('g_SamplerFresnel')
samplers['g_SamplerDither']['previous'].discard('g_SamplerFresnel')

struct_names = [*structs]
struct_names.sort()

for name in struct_names:
    print('struct %s' % (name,))
    print('{')
    print(indent(structs[name]['body']))
    print('};')
    print()
while len(cbuffers) > 0:
    some_cbuffers = pomap_get(cbuffers)
    cbuffers_names = [*some_cbuffers]
    cbuffers_names.sort()
    print('// ------- //')
    for cbuf_name in cbuffers_names:
        cbuf_def = some_cbuffers[cbuf_name]
        if len(cbuf_def['bodies']) > 1:
            for (body, packages) in cbuf_def['bodies'].items():
                print('#if ' + ' || '.join('defined(SHPK_%s)' % (package.upper(),) for package in packages))
                print('cbuffer %s // after %s' % (cbuf_name, ', '.join(cbuf_def['orig_previous']) if 'orig_previous' in cbuf_def else ''))
                print('{')
                print(indent(body))
                print('}')
                print('#endif')
        else:
            print('cbuffer %s // after %s' % (cbuf_name, ', '.join(cbuf_def['orig_previous']) if 'orig_previous' in cbuf_def else ''))
            print('{')
            print(indent(next(cbuf_def['bodies'].__iter__())))
            print('}')
        print()
while len(samplers) > 0:
    some_samplers = pomap_get(samplers)
    samplers_names = [*some_samplers]
    samplers_names.sort()
    print('// ------- //')
    for samp_name in samplers_names:
        samp_def = some_samplers[samp_name]
        if len(samp_def['types']) > 1:
            for (samp_type, packages) in samp_def['types'].items():
                print('#if ' + ' || '.join('defined(SHPK_%s)' % (package.upper(),) for package in packages))
                print('%s %s; // after %s' % (samp_type, samp_name, ', '.join(samp_def['orig_previous']) if 'orig_previous' in samp_def else ''))
                print('#endif')
        else:
            print('%s %s; // after %s' % (next(samp_def['types'].__iter__()), samp_name, ', '.join(samp_def['orig_previous']) if 'orig_previous' in samp_def else ''))
