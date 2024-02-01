#!/usr/bin/env python3

import os
import re
import sys
from minihlsl import BlockStack, Variable, UninitializedNode, NameNode, Context
from shpatterns import simplify_shader_patterns, name_shader_variables

ARG_PATTERN = re.compile(r'^(out )?([A-Za-z_]+)([0-9]+)? ([A-Za-z0-9_]+) : [A-Za-z0-9_]+[,)]$')
DECL_PATTERN = re.compile(r'^(\S.*) ([^ ]+) : (.*);$')

# This script cuts a lot of corners, therefore:
# This file MUST be an unmodified etnlGD/HLSLDecompiler (fork of 3Dmigoto decompiler) output

context = Context()

with open(sys.argv[1], 'rt') as file:
    shader = file.read()

# Optional file with name mappings
if len(sys.argv) > 2:
    with open(sys.argv[2], 'rt') as nmfile:
        for line in nmfile.read().split('\n'):
            words = line.split(' ')
            if len(words) >= 2:
                context.name_mappings[words[0]] = words[1]

# Split and number lines

shader = [(i, line) for (i, line) in enumerate(shader.split('\n'))]

# Trim trailing \r and whitespace

shader = [(i, line.rstrip()) for (i, line) in shader]

# Clean up declarations

decls = [(i, match) for (i, match) in ((i, DECL_PATTERN.fullmatch(line)) for (i, line) in shader) if match is not None]
already_processed_decls = set()

for (i, decl) in decls:
    name = decl.group(2)
    if name in already_processed_decls:
        continue
    already_processed_decls.add(name)
    uses = sum(1 for (j, line) in shader if name in line and j != i)
    if uses == 0:
        shader = [(j, line) for (j, line) in shader if j != i]
        continue
    if '.' in name:
        sibling_indices = set()
        pos = name.index('.')
        global_name = name[0:pos]
        prefix = global_name + '.'
        struct_decl = [(-1, ''), (-1, 'struct {')]
        for (j, decl2) in decls:
            name2 = decl2.group(2)
            if name2.startswith(prefix):
                already_processed_decls.add(name2)
                sibling_indices.add(j)
                struct_decl.append((-1, '  %s %s;' % (decl2.group(1), name2[(pos + 1):])))
        struct_decl.append((-1, '} %s : %s;' % (global_name, decl.group(3))))
        shader_before = [(j, line) for (j, line) in shader if j < i and j not in sibling_indices]
        shader_after = [(j, line) for (j, line) in shader if j > i and j not in sibling_indices]
        shader = shader_before
        shader.extend(struct_decl)
        shader.extend(shader_after)

# Convert main() into a SSA-ish form, simplify literals

main_start = next((i for (i, line) in shader if line == 'void main('))

shader_header = []
shader_main = []

blocks = BlockStack()

parser_state = 0
for (i, raw_line) in shader:
    line = raw_line.lstrip(' ')
    if line.startswith('//'):
        continue
    if parser_state == 0:
        if raw_line == 'void main(':
            shader_main.append((i, raw_line))
            parser_state = 1
        else:
            shader_header.append((i, raw_line))
        continue
    if parser_state == 1:
        shader_main.append((i, raw_line))
        if raw_line == '{':
            parser_state = 2
        arg = ARG_PATTERN.fullmatch(line)
        if arg is not None:
            arg_t = arg.group(2)
            arg_n = arg.group(3)
            arg_n = 1 if arg_n is None else int(arg_n)
            arg_nm = arg.group(4)
            if arg.group(1) is not None:
                blocks.root.scope.declare(Variable(arg_t, arg_n, arg_nm, lambda _: UninitializedNode(arg_t).simplify()))
                context.outs.add(arg_nm)
            else:
                arg_node = NameNode(arg_t + (str(arg_n) if arg_n > 1 else ''), arg_nm).simplify()
                blocks.root.scope.declare(Variable(arg_t, arg_n, arg_nm, lambda component: arg_node.member(component)))
        continue
    if raw_line == '  return;' or raw_line == '}':
        break
    if len(line) == 0:
        continue
    if not blocks.parse_line(line):
        level = (len(raw_line) - len(line)) >> 1
        raise NotImplementedError('at level %d, unrecognized line "%s"' % (level, line))

blocks.root.resolve(context)
simplify_shader_patterns(blocks.root)
blocks.full_prune()
blocks.root.simplify_final()
name_shader_variables(blocks.root)
blocks.root.simplify_final()
blocks.root.write_to(shader_main, '  ')

shader_main.append((-1, '}'))

shader = shader_header
shader.extend(shader_main)

out_name = os.path.basename(sys.argv[1]).split('.')
out_name[-3 if len(out_name) >= 3 else 0] += "-fix"

with open(os.path.join(os.path.dirname(sys.argv[1]), '.'.join(out_name)), 'wt') as file:
    file.write('\n'.join(line for (_, line) in shader))
