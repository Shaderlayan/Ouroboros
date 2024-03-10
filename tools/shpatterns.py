from minihlsl import Block, Instruction, BlockInstruction, AssignmentInstruction, DeclarationInstruction, name, NameNode, CastNode, MemberAccessNode, Node, BinaryOpNode, SwizzleNode, FunctionCallNode, fn_call, literal, UnaryOpNode, IndexNode, ConditionalNode, no_match_inner, CUSTOM_FUNCTION_MASKS
from pattern import PatternOr, PatternSlot, PatternHead, PatternSet, PatternSubset, matches_pattern, ANY

def visit_instructions(block: Block, visitor, acc) -> None:
    for insn in block.instructions:
        if isinstance(insn, BlockInstruction):
            for child_block in insn.child_blocks():
                acc = visit_instructions(child_block, visitor, acc)
        acc = visitor(insn, acc)
    return acc

def visit_instructions_reversed(block: Block, visitor, acc) -> None:
    for insn in reversed(block.instructions):
        acc = visitor(insn, acc)
        if isinstance(insn, BlockInstruction):
            for child_block in reversed(insn.child_blocks()):
                acc = visit_instructions(child_block, visitor, acc)
    return acc

CUSTOM_FUNCTION_MASKS['luminance'] = 7
CUSTOM_FUNCTION_MASKS['MUL_3X4_ROWS'] = 15
CUSTOM_FUNCTION_MASKS['ambientColor'] = 7

NAMED_PATTERNS = {
    'ambient_light.viewZ2': PatternSlot('viewZ2', BinaryOpNode(name('g_AmbientParam').index(literal('4')).member('y'), '+', BinaryOpNode(
        name('g_AmbientParam').index(literal('4')).member('x'), '*', PatternSlot('viewZ')))),
    'table_vnum_from_index.filter': PatternSlot('filter', fn_call('frac', [BinaryOpNode(literal('7.5'), '*', PatternSlot('index'))])),
    'tile_texcoord.uv_transform': PatternSlot('uv_transform', MemberAccessNode(None, ANY, 'm_TileUVTransform')),
    'bloom.bloomNumSq': PatternSlot(
        'bloomNumSq',
        PatternOr(
            BinaryOpNode(
                BinaryOpNode(name('g_CommonParameter').member('m_Misc').member('xxx'), '*', PatternSlot('specularComponent')),
                '+',
                BinaryOpNode(name('g_InstanceParameter').member('m_EnvParameter').member('www'), '*', PatternSlot('emissiveColor')),
            ),
            BinaryOpNode(name('g_CommonParameter').member('m_Misc').member('xxx'), '*', PatternSlot('specularComponent')),
            BinaryOpNode(name('g_InstanceParameter').member('m_EnvParameter').member('www'), '*', PatternSlot('emissiveColor')),
        ),
    ),
    'bloom.finalSq': PatternSlot(
        'finalSq',
        PatternOr(
            BinaryOpNode(PatternSlot('diffuseComponent'), '+', BinaryOpNode(PatternSlot('specularComponent'), '+', PatternSlot('emissiveColor'))),
            BinaryOpNode(PatternSlot('diffuseComponent'), '+', PatternSlot('specularComponent')),
        ),
    ),
}

NAMED_PATTERNS.update({
    'bloom.bmMax1': PatternSlot(
        'bmMax1',
        fn_call('max', PatternSet(
            fn_call('float4', [SwizzleNode(NAMED_PATTERNS['bloom.bloomNumSq'], 'x'), SwizzleNode(NAMED_PATTERNS['bloom.bloomNumSq'], 'y'), SwizzleNode(NAMED_PATTERNS['bloom.finalSq'], 'x'), SwizzleNode(NAMED_PATTERNS['bloom.finalSq'], 'y')]),
            fn_call('float4', [SwizzleNode(NAMED_PATTERNS['bloom.bloomNumSq'], 'z'), literal('0'), SwizzleNode(NAMED_PATTERNS['bloom.finalSq'], 'z'), literal('0.001')]),
        )),
    ),
})

NAMED_PATTERNS.update({
    'bloom.bmMax2': PatternSlot(
        'bmMax2',
        fn_call('max', PatternSet(
            fn_call('float2', [SwizzleNode(NAMED_PATTERNS['bloom.bmMax1'], 'x'), SwizzleNode(NAMED_PATTERNS['bloom.bmMax1'], 'z')]),
            fn_call('float2', [SwizzleNode(NAMED_PATTERNS['bloom.bmMax1'], 'y'), SwizzleNode(NAMED_PATTERNS['bloom.bmMax1'], 'w')]),
        )),
    ),
})

NAMED_PATTERNS.update({
    'dot-': fn_call('dot', PatternSet(no_match_inner(UnaryOpNode('-', PatternSlot('a'))), PatternSlot('b'))),
    'sampler.Sample': MemberAccessNode(None, PatternSlot('sampler'), 'T').fn_call(PatternSlot('fn'), PatternHead([MemberAccessNode(None, PatternSlot('sampler'), PatternOr('S', 'S_s'))], 'args')),
    'POW': fn_call('exp2', [BinaryOpNode(fn_call('log2', [PatternSlot('base')]), '*', PatternSlot('exponent'))]),
    'normalize': BinaryOpNode(PatternSlot('vec'), '*', fn_call('rsqrt', [fn_call('dot', [PatternSlot('vec'), PatternSlot('vec')])])),
    'reflect': UnaryOpNode('-', BinaryOpNode(PatternSlot('incident'), '+', BinaryOpNode(PatternSlot('normal'), '*', BinaryOpNode(
        UnaryOpNode('-', fn_call('dot', PatternSet(PatternSlot('incident'), PatternSlot('normal')))), '+',
        UnaryOpNode('-', fn_call('dot', PatternSet(PatternSlot('incident'), PatternSlot('normal')))))))),
    'lerp': BinaryOpNode(BinaryOpNode(BinaryOpNode(PatternSlot('y'), '-', PatternSlot('x')), '*', PatternSlot('s')), '+', PatternSlot('x')),
    'lerp+': BinaryOpNode(BinaryOpNode(BinaryOpNode(BinaryOpNode(PatternSlot('y'), '-', PatternSlot('x')), '*', PatternSlot('s')), '+', PatternSlot('x')), '+', PatternSlot('rest')),
    'lerp-': BinaryOpNode(BinaryOpNode(BinaryOpNode(PatternSlot('x'), '-', PatternSlot('y')), '*', PatternSlot('s')), '+', PatternSlot('x')),
    'mul(f3x3, f3)': fn_call('float3', [
        fn_call('dot', PatternSet(MemberAccessNode(None, PatternSlot('mat'), '_m00_m01_m02'), PatternSlot('vec'))),
        fn_call('dot', PatternSet(MemberAccessNode(None, PatternSlot('mat'), '_m10_m11_m12'), PatternSlot('vec'))),
        fn_call('dot', PatternSet(MemberAccessNode(None, PatternSlot('mat'), '_m20_m21_m22'), PatternSlot('vec'))),
    ]),
    'mul(f3x4, f4)': fn_call('float3', [
        fn_call('dot', PatternSet(MemberAccessNode(None, PatternSlot('mat'), '_m00_m01_m02_m03'), PatternSlot('vec'))),
        fn_call('dot', PatternSet(MemberAccessNode(None, PatternSlot('mat'), '_m10_m11_m12_m13'), PatternSlot('vec'))),
        fn_call('dot', PatternSet(MemberAccessNode(None, PatternSlot('mat'), '_m20_m21_m22_m23'), PatternSlot('vec'))),
    ]),
    'clamp': fn_call('min', PatternSet(fn_call('max', [PatternSlot('min'), PatternSlot('value')]), PatternSlot('max'))),
    'luminance': fn_call('dot', PatternSet(fn_call('float3', [literal('0.29891'), literal('0.58661'), literal('0.11448')]), PatternSlot('color'))),
    'x OP literal through float2': PatternOr(
        SwizzleNode(BinaryOpNode(fn_call('float2', [PatternSlot('vec_comp'), ANY]), PatternSlot('op'), PatternSlot('scalar')), 'x'),
        SwizzleNode(BinaryOpNode(fn_call('float2', [ANY, PatternSlot('vec_comp')]), PatternSlot('op'), PatternSlot('scalar')), 'y'),
    ),
    'autoNormal': fn_call('normalize', [fn_call('float3', [
        SwizzleNode(BinaryOpNode(PatternSlot('normalSample'), '-', literal('0.5')), 'x'),
        SwizzleNode(BinaryOpNode(PatternSlot('normalSample'), '-', literal('0.5')), 'y'),
        fn_call('sqrt', [fn_call('max', PatternSet(literal('0'), BinaryOpNode(literal('0.25'), '-', fn_call('dot', [BinaryOpNode(PatternSlot('normalSample'), '-', literal('0.5')), BinaryOpNode(PatternSlot('normalSample'), '-', literal('0.5'))]))))]),
    ])]),
    'autoNormal2': fn_call('normalize', [fn_call('float3', [
        SwizzleNode(BinaryOpNode(BinaryOpNode(PatternSlot('normalSample'), '-', literal('0.5')), '*', PatternSlot('normalScale')), 'x'),
        SwizzleNode(BinaryOpNode(BinaryOpNode(PatternSlot('normalSample'), '-', literal('0.5')), '*', PatternSlot('normalScale')), 'y'),
        fn_call('sqrt', [fn_call('max', PatternSet(literal('0'), BinaryOpNode(literal('0.25'), '-', fn_call('dot', [BinaryOpNode(PatternSlot('normalSample'), '-', literal('0.5')), BinaryOpNode(PatternSlot('normalSample'), '-', literal('0.5'))]))))]),
    ])]),
    'NORMAL': BinaryOpNode(
        BinaryOpNode(fn_call('normalize', [name('v4').member('xyz')]), '*', SwizzleNode(PatternSlot('tsNormal'), 'z')),
        '+',
        BinaryOpNode(
            BinaryOpNode(fn_call('normalize', [name('v5').member('xyz')]), '*', SwizzleNode(PatternSlot('tsNormal'), 'x')),
            '+',
            BinaryOpNode(fn_call('normalize', [name('v6').member('xyz')]), '*', SwizzleNode(PatternSlot('tsNormal'), 'y')),
        )
    ),
    'vector overlay': BinaryOpNode(
        BinaryOpNode(
            BinaryOpNode(literal('1'), '-', fn_call('abs', [PatternSlot('over')])),
            '*',
            BinaryOpNode(
                fn_call('float3', [
                    ConditionalNode(CastNode('int', SwizzleNode(fn_call('cmp', [BinaryOpNode(literal('0'), '<', PatternSlot('over'))]), 'x')), literal('-1'), literal('1')),
                    ConditionalNode(CastNode('int', SwizzleNode(fn_call('cmp', [BinaryOpNode(literal('0'), '<', PatternSlot('over'))]), 'y')), literal('-1'), literal('1')),
                    ConditionalNode(CastNode('int', SwizzleNode(fn_call('cmp', [BinaryOpNode(literal('0'), '<', PatternSlot('over'))]), 'z')), literal('-1'), literal('1')),
                ]),
                '+',
                PatternSlot('under'),
            ),
        ),
        '+',
        fn_call('float3', [
            ConditionalNode(CastNode('int', SwizzleNode(fn_call('cmp', [BinaryOpNode(literal('0'), '<', PatternSlot('over'))]), 'x')), literal('1'), literal('-1')),
            ConditionalNode(CastNode('int', SwizzleNode(fn_call('cmp', [BinaryOpNode(literal('0'), '<', PatternSlot('over'))]), 'y')), literal('1'), literal('-1')),
            ConditionalNode(CastNode('int', SwizzleNode(fn_call('cmp', [BinaryOpNode(literal('0'), '<', PatternSlot('over'))]), 'z')), literal('1'), literal('-1')),
        ]),
    ),

    'normal_gbuffer': fn_call('normalize', [BinaryOpNode(SwizzleNode(PatternSlot('gbs'), 'xyz'), '-', literal('0.5'))]),
    'shininess_gbuffer': UnaryOpNode('-', BinaryOpNode(literal('15'), '*', fn_call('log2', [
        fn_call('clamp', [SwizzleNode(PatternSlot('gbs'), 'w'), literal('0.002'), literal('0.99')])]))),
    'mul(array[0..2], f4)': fn_call('float3', [
        fn_call('saturate', [fn_call('dot', PatternSet(SwizzleNode(IndexNode(None, PatternSlot('array'), literal('0')), 'xyzw'), PatternSlot('vec')))]),
        fn_call('saturate', [fn_call('dot', PatternSet(SwizzleNode(IndexNode(None, PatternSlot('array'), literal('1')), 'xyzw'), PatternSlot('vec')))]),
        fn_call('saturate', [fn_call('dot', PatternSet(SwizzleNode(IndexNode(None, PatternSlot('array'), literal('2')), 'xyzw'), PatternSlot('vec')))]),
    ]),
    'ambient_color': BinaryOpNode(name('g_AmbientParam').index(literal('3')).member('www'), '*', fn_call('saturate', [
        fn_call('MUL_3X4_ROWS', [name('g_AmbientParam'), literal('0'), fn_call('float4', [PatternSlot('x'), PatternSlot('y'), PatternSlot('z'), literal('1')])])])),
    'ambient_light': BinaryOpNode(fn_call('ambientColor', [PatternSlot('normal')]), '*',
        fn_call('clamp', [BinaryOpNode(fn_call('abs', [NAMED_PATTERNS['ambient_light.viewZ2']]), '*', NAMED_PATTERNS['ambient_light.viewZ2'],), name('g_AmbientParam').index(literal('4')).member('z'), literal('1')]),
    ),
    'reflection_color': BinaryOpNode(BinaryOpNode(name('g_AmbientParam').index(literal('5')).member('y'), '+', fn_call('dot', PatternSet(
        name('g_AmbientParam').index(literal('5')).member('xx'),
        name('g_SamplerReflection').member('SampleLevel').call([
            fn_call('normalize', [fn_call('mul', [name('g_CameraParameter').member('m_InverseViewMatrix'), PatternSlot('reflection')])]),
            BinaryOpNode(literal('1'), '+', BinaryOpNode(literal('0.75'), '*', BinaryOpNode(literal('7'), '-', fn_call('log2', [PatternSlot('shininess')])))),
        ]).member('x'),
    ))), '*', fn_call('ambientColor', [PatternSlot('reflection')])),
    'final_occlusion_value': BinaryOpNode(PatternSlot('value'), '+', BinaryOpNode(name('g_SceneParameter').member('m_OcclusionIntensity').member('w'), '*', BinaryOpNode(
        literal('1'), '+', UnaryOpNode('-', fn_call('lerp', [PatternSlot('value'), literal('1'), literal(PatternSlot('interp'))]))))),
    'table_vnum_from_index': BinaryOpNode(literal('0.5'), '+', fn_call('lerp', [
        BinaryOpNode(literal('15'), '*', PatternSlot('index')),
        fn_call('floor', [BinaryOpNode(literal('0.5'), '+', BinaryOpNode(literal('15'), '*', PatternSlot('index')))]),
        fn_call('floor', [BinaryOpNode(NAMED_PATTERNS['table_vnum_from_index.filter'], '+', NAMED_PATTERNS['table_vnum_from_index.filter'])]),
    ])),
    'table_lookup_diffuse_column': FunctionCallNode(None, name('g_SamplerTable'), 'Sample', [fn_call('float2', [
        literal('0.125'),
        BinaryOpNode(literal('0.0625'), '*', fn_call('table_vnum_from_index', [PatternSlot('index')])),
    ])]).member('xyzw'),
    'table_lookup_diffuse': FunctionCallNode(None, name('g_SamplerTable'), 'Sample', [fn_call('float2', [
        literal('0.125'),
        BinaryOpNode(literal('0.0625'), '*', fn_call('table_vnum_from_index', [PatternSlot('index')])),
    ])]).member('xyz'),
    'table_lookup_specmask': FunctionCallNode(None, name('g_SamplerTable'), 'Sample', [fn_call('float2', [
        literal('0.125'),
        BinaryOpNode(literal('0.0625'), '*', fn_call('table_vnum_from_index', [PatternSlot('index')])),
    ])]).member('w'),
    'table_lookup_specular_column': FunctionCallNode(None, name('g_SamplerTable'), 'Sample', [fn_call('float2', [
        literal('0.375'),
        BinaryOpNode(literal('0.0625'), '*', fn_call('table_vnum_from_index', [PatternSlot('index')])),
    ])]).member('xyzw'),
    'table_lookup_fresnel': FunctionCallNode(None, name('g_SamplerTable'), 'Sample', [fn_call('float2', [
        literal('0.375'),
        BinaryOpNode(literal('0.0625'), '*', fn_call('table_vnum_from_index', [PatternSlot('index')])),
    ])]).member('xyz'),
    'table_lookup_shininess': FunctionCallNode(None, name('g_SamplerTable'), 'Sample', [fn_call('float2', [
        literal('0.375'),
        BinaryOpNode(literal('0.0625'), '*', fn_call('table_vnum_from_index', [PatternSlot('index')])),
    ])]).member('w'),
    'table_lookup_emissive': FunctionCallNode(None, name('g_SamplerTable'), 'Sample', [fn_call('float2', [
        literal('0.625'),
        BinaryOpNode(literal('0.0625'), '*', fn_call('table_vnum_from_index', [PatternSlot('index')])),
    ])]).member('xyz'),
    'table_lookup_tilew': FunctionCallNode(None, name('g_SamplerTable'), 'Sample', [fn_call('float2', [
        literal('0.625'),
        BinaryOpNode(literal('0.0625'), '*', BinaryOpNode(literal('0.5'), '+', fn_call('floor', [fn_call('table_vnum_from_index', [PatternSlot('index')])]))),
    ])]).member('w'),
    'table_lookup_tileuv': FunctionCallNode(None, name('g_SamplerTable'), 'Sample', [fn_call('float2', [
        literal('0.875'),
        BinaryOpNode(literal('0.0625'), '*', fn_call('table_vnum_from_index', [PatternSlot('index')])),
    ])]).member('xyzw'),
    'nearest_neighbor_64': BinaryOpNode(literal('0.015625'), '*', BinaryOpNode(literal('0.5'), '+', fn_call('floor', [BinaryOpNode(literal('64'), '*', PatternSlot('value'))]))),
    'tile_texcoord': fn_call('float3', [
        fn_call('dot', PatternSet(SwizzleNode(NAMED_PATTERNS['tile_texcoord.uv_transform'], 'xy'), PatternSlot('uv'))),
        fn_call('dot', PatternSet(SwizzleNode(NAMED_PATTERNS['tile_texcoord.uv_transform'], 'zw'), PatternSlot('uv'))),
        PatternSlot('w'),
    ]),
    'occlude_diffuse': ConditionalNode(
        fn_call('cmp', [BinaryOpNode(literal('0'), '<', SwizzleNode(MemberAccessNode(None, name('g_SceneParameter'), 'm_OcclusionIntensity'), 'w'))]),
        BinaryOpNode(PatternSlot('diffuse'), '+', BinaryOpNode(fn_call('POW', [
            fn_call('saturate', [PatternSlot('diffuse')]),
            fn_call('lerp', [literal('1'), PatternSlot('occlusion'), UnaryOpNode('-', BinaryOpNode(literal('0.25'), '*', fn_call(
                'saturate', [BinaryOpNode(literal('0.5'), '+', BinaryOpNode(literal('0.5'), '*', fn_call('luminance', [PatternSlot('diffuse')])))])))]),
        ]), '-', fn_call('saturate', [PatternSlot('diffuse')]))),
        PatternSlot('diffuse')),
    'bloom': BinaryOpNode(SwizzleNode(NAMED_PATTERNS['bloom.bmMax2'], 'x'), '/', SwizzleNode(NAMED_PATTERNS['bloom.bmMax2'], 'y')),
})

NAMED_VARIABLES = {
    'normal_gbuffer': 'normal',
    'shininess_gbuffer': 'shininess',
    'ambient_light': {'': 'lightAmbient', 'occlusionValue': 'occlusionValue'},
    'final_occlusion_value': {'': 'finalOcclusionValue', 'value': 'occlusionValue'},
}

EXPR_SIMPLIFICATIONS = {
    'dot-': lambda a, b: fn_call('dot', [a, b]).unary_op('-'),
    'sampler.Sample': lambda sampler, fn, args: sampler.fn_call(fn, args),
    'POW': lambda base, exponent: fn_call('POW', [base, exponent]),
    'normalize': lambda vec: fn_call('normalize', [vec]),
    'reflect': lambda incident, normal: fn_call('reflect', [incident, normal]),
    'lerp': lambda x, y, s: fn_call('lerp', [x, y, s]),
    'lerp+': lambda x, y, s, rest: BinaryOpNode(fn_call('lerp', [x, y, s]), '+', rest),
    'lerp-': lambda x, y, s: fn_call('lerp', [x, y, s.unary_op('-')]),
    'mul(f3x3, f3)': lambda mat, vec: fn_call('mul', [mat, vec]),
    'mul(f3x4, f4)': lambda mat, vec: fn_call('mul', [mat, vec]),
    'clamp': lambda value, min, max: fn_call('clamp', [value, min, max]),
    'luminance': lambda color: fn_call('luminance', [color]),
    'x OP literal through float2': lambda vec_comp, op, scalar: BinaryOpNode(vec_comp, op, scalar),
    'autoNormal': lambda normalSample: fn_call('autoNormal', [normalSample]),
    'autoNormal2': lambda normalSample, normalScale: fn_call('autoNormal', [normalSample, normalScale]),
    'NORMAL': lambda tsNormal: fn_call('NORMAL', [tsNormal]),
    'vector overlay': lambda under, over: fn_call('lerp', [under, fn_call('sign', [over]), fn_call('abs', [over])]),

    'normal_gbuffer': lambda gbs: fn_call('normalFromGBuffer', [gbs]),
    'shininess_gbuffer': lambda gbs: fn_call('shininessFromGBuffer', [gbs]),
    'ambient_color': lambda x, y, z: fn_call('ambientColor', [fn_call('float3', [x, y, z]).simplify()]),
    'ambient_light': lambda normal, viewZ, viewZ2: (print(normal, viewZ, viewZ2), fn_call('ambientLight', [normal, viewZ]))[1],
    'reflection_color': lambda reflection, shininess: fn_call('reflectionColor', [reflection, shininess]),
    'final_occlusion_value': lambda value, interp: fn_call('lerp', [value, literal('1'), BinaryOpNode(name('g_SceneParameter').member('m_OcclusionIntensity').member('w'), '*', literal(str(1 - float(interp))))]),
    'mul(array[0..2], f4)': lambda array, vec: fn_call('saturate', [fn_call('MUL_3X4_ROWS', [array, literal('0'), vec])]),
    'table_vnum_from_index': lambda index, filter: fn_call('table_vnum_from_index', [index]),
    'table_lookup_diffuse_column': lambda index: name('g_SamplerTable').fn_call('Lookup', [index]).member('m_DiffuseColumn'),
    'table_lookup_diffuse': lambda index: name('g_SamplerTable').fn_call('Lookup', [index]).member('m_DiffuseColor'),
    'table_lookup_specmask': lambda index: name('g_SamplerTable').fn_call('Lookup', [index]).member('m_SpecularMask'),
    'table_lookup_specular_column': lambda index: name('g_SamplerTable').fn_call('Lookup', [index]).member('m_SpecularColumn'),
    'table_lookup_fresnel': lambda index: name('g_SamplerTable').fn_call('Lookup', [index]).member('m_FresnelValue0'),
    'table_lookup_shininess': lambda index: name('g_SamplerTable').fn_call('Lookup', [index]).member('m_Shininess'),
    'table_lookup_emissive': lambda index: name('g_SamplerTable').fn_call('Lookup', [index]).member('m_EmissiveColor'),
    'table_lookup_tilew': lambda index: name('g_SamplerTable').fn_call('Lookup', [index]).member('m_TileW'),
    'table_lookup_tileuv': lambda index: name('g_SamplerTable').fn_call('Lookup', [index]).member('m_TileUVTransform'),
    'nearest_neighbor_64': lambda value: fn_call('nearestNeighbor64', [value]),
    'tile_texcoord': lambda uv_transform, uv, w: fn_call('float3', [fn_call('mul', [uv_transform, uv]), w]),
    'occlude_diffuse': lambda diffuse, occlusion: fn_call('occludeDiffuse', [diffuse, occlusion]),
    'bloom': lambda diffuseComponent, specularComponent, emissiveColor, **kwargs: fn_call('bloom', [diffuseComponent, specularComponent, emissiveColor]),
    #'bloom': lambda **kwargs: None if print(kwargs) else None,
}

def simplify_expression(node: Node, state: tuple) -> tuple:
    (any_change, var_name) = state
    (any_change_here, _) = node.visit_children(simplify_expression, (False, None))
    for name, replacement in EXPR_SIMPLIFICATIONS.items():
        match = matches_pattern(node, NAMED_PATTERNS[name], {})
        if match is not None:
            if name in NAMED_VARIABLES:
                var_name = NAMED_VARIABLES[name]
                if isinstance(var_name, dict):
                    for mn, vn in var_name.items():
                        if mn in match:
                            name_variable(match[mn], vn)
                    var_name = var_name[''] if '' in var_name else None
            return simplify_expression(replacement(**match).simplify(), (True, var_name))
    return (node.simplify() if any_change_here else node, (any_change_here or any_change, var_name))

def simplify_insn_expressions(insn: Instruction, any_change: bool) -> bool:
    if (isinstance(insn, DeclarationInstruction) or isinstance(insn, AssignmentInstruction)) and insn.value is not None:
        (insn.value, (any_change, name)) = simplify_expression(insn.value, (any_change, None))
        if name is not None and isinstance(insn, DeclarationInstruction):
            insn.name = name
            any_change = True
    return any_change

def name_variable(variable: Node, name: str) -> bool:
    if isinstance(variable, NameNode) and isinstance(variable._name, DeclarationInstruction):
        variable._name.name = name
        return True
    return False

def name_all_variables(variables: dict) -> bool:
    any_change = False
    for name, variable in variables.items():
        if name_variable(variable, name):
            any_change = True
    return any_change

def name_known_variables_backwards(insn: Instruction, any_change: bool) -> bool:
    match insn:
        # o0.w = bmMax2.x / bmMax2.y
        # bmMax2 = max(bmMax1.xz, bmMax1.yw)
        # bmMax1 = max(float4(bloomNumSq.xy, finalSq.xy), float4(bloomNumSq.z, 0, finalSq.z, 0.001))
        # bmMax1 = max(float4(bloomNumSq.z, 0, finalSq.z, 0.001), float4(bloomNumSq.xy, finalSq.xy))
        case AssignmentInstruction(name='o0', mask='w', value=o0w):
            match = matches_pattern(o0w, NAMED_PATTERNS['bloom'], {})
            if match is not None:
                return name_all_variables(match) or any_change
        # bloomNumSq = g_CommonParameter.m_Misc.xxx * specularComponent + g_InstanceParameter.m_EnvParameter.www * emissiveColor
        case DeclarationInstruction(name='bloomNumSq', value=bloomNumSq):
            bloomSpec = BinaryOpNode(name('g_CommonParameter').member('m_Misc').member('xxx'), '*', PatternSlot('specularComponent'))
            bloomEmi = BinaryOpNode(name('g_InstanceParameter').member('m_EnvParameter').member('www'), '*', PatternSlot('emissiveColor'))
            match = matches_pattern(bloomNumSq, PatternOr(
                BinaryOpNode(bloomSpec, '+', bloomEmi),
                bloomSpec,
                bloomEmi,
            ), {})
            if match is not None:
                return name_all_variables(match) or any_change
    return any_change

def simplify_shader_patterns(block: Block) -> None:
    visit_instructions(block, simplify_insn_expressions, False)

def name_shader_variables(block: Block) -> None:
    visit_instructions_reversed(block, name_known_variables_backwards, False)
