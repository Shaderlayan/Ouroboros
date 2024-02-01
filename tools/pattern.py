def has_method(obj, method):
    return callable(getattr(obj, method, None))

class PatternElement:
    def __init__(self) -> None:
        self.type = None # HACK for use in expression trees
    def __str__(self) -> str:
        return self.value_str()
    @property
    def innermost(self):
        return self
    def accepts(self, value, slots: dict) -> dict | None:
        return None

class PatternOr(PatternElement):
    def __init__(self, *nodes) -> None:
        super().__init__()
        self.nodes = nodes
    def __hash__(self) -> int:
        return hash((self.nodes,))
    def __eq__(self, other) -> bool:
        return self is other or (isinstance(other, PatternOr) and len(self.nodes) == len(other.nodes) and all(sn == on for (sn, on) in zip(self.nodes, other.nodes)))
    def value_str(self) -> str:
        return '{%s}' % (', '.join(self.nodes),)
    def accepts(self, value, slots: dict) -> dict | None:
        for subpattern in self.nodes:
            match_slots = matches_pattern(value, subpattern, slots)
            if match_slots is not None:
                return match_slots
        return None

class PatternSlot(PatternElement):
    def __init__(self, name: str | None, sub_pattern = None) -> None:
        super().__init__()
        self.name = name
        self.sub_pattern = sub_pattern
    def __hash__(self) -> int:
        return hash((self.name, self.sub_pattern))
    def __eq__(self, other) -> bool:
        return self is other or (isinstance(other, PatternSlot) and self.name == other.name and self.sub_pattern == other.sub_pattern)
    def value_str(self) -> str:
        if self.sub_pattern is not None:
            return '<%s: %s>' % (self.name, self.sub_pattern)
        return '<%s>' % (self.name,)
    def accepts(self, value, slots: dict) -> dict | None:
        if self.name is None:
            if self.sub_pattern is not None:
                return matches_pattern(value, self.sub_pattern, slots)
            return slots
        if self.name in slots:
            slots = matches_base(value, slots[self.name], slots)
            if slots is None:
                return None
            if self.sub_pattern is not None:
                return matches_pattern(value, self.sub_pattern, slots)
            return slots
        slots = slots.copy()
        slots[self.name] = value
        if self.sub_pattern is not None:
            return matches_pattern(value, self.sub_pattern, slots)
        return slots

class PatternHead(PatternElement):
    def __init__(self, head: list, tail_name: str | None, tail_hook = None, tail_sub_pattern = None):
        super().__init__()
        self.head = head
        self.tail_name = tail_name
        self.tail_hook = tail_hook
        self.tail_sub_pattern = tail_sub_pattern
    def __hash__(self) -> int:
        return hash(((*self.head,) if isinstance(self.head, list) else self.head, self.tail_name, self.tail_hook, self.tail_sub_pattern))
    def __eq__(self, other) -> bool:
        return self is other or (isinstance(other, PatternHead) and self.tail_name == other.tail_name and self.tail_hook == other.tail_hook and len(self.head) == len(other.head) and all(sitem == oitem for (sitem, oitem) in zip(self.head, other.head)))
    def value_str(self) -> str:
        return '<HEAD>'
    def __len__(self):
        return len(self.head)
    def __iter__(self):
        return self.head.__iter__()
    def accepts(self, value, slots: dict) -> dict | None:
        head_len = len(self.head)
        if not isinstance(value, list) or len(value) < head_len:
            return None
        slots = matches_pattern(value[:head_len], self.head, slots)
        if slots is None:
            return None
        if self.tail_name is None and self.tail_sub_pattern is None:
            return slots
        tail = value[head_len:]
        if self.tail_hook is not None:
            tail = self.tail_hook(tail)
        if self.tail_name is not None:
            slots = slots.copy()
            slots[self.tail_name] = tail
        if self.tail_sub_pattern is not None:
            return matches_pattern(tail, self.tail_sub_pattern, slots)
        return slots

class PatternSet(PatternElement):
    def __init__(self, *items):
        super().__init__()
        self.items = items
    def __hash__(self) -> int:
        return hash((self.items,))
    def __eq__(self, other) -> bool:
        return self is other or (isinstance(other, PatternSet) and len(self.items) == len(other.items) and all(sitem == oitem for (sitem, oitem) in zip(self.items, other.items)))
    def value_str(self) -> str:
        return '<SET>'
    def __len__(self):
        return len(self.items)
    def __iter__(self):
        return self.items.__iter__()
    def accepts(self, value, slots: dict) -> dict | None:
        if len(value) != len(self.items):
            return None
        (rest, slots) = matches_set_helper(value, self.items, None, slots)
        if slots is None or len(rest) > 0:
            return None
        return slots

class PatternSubset(PatternElement):
    def __init__(self, items, rest_name: str | None, rest_hook = None, rest_sub_pattern = None):
        super().__init__()
        self.items = items
        self.rest_name = rest_name
        self.rest_hook = rest_hook
        self.rest_sub_pattern = rest_sub_pattern
    def __hash__(self) -> int:
        return hash((self.items,))
    def __eq__(self, other) -> bool:
        return self is other or (isinstance(other, PatternSet) and len(self.items) == len(other.items) and all(sitem == oitem for (sitem, oitem) in zip(self.items, other.items)))
    def value_str(self) -> str:
        return '<SUBSET>'
    def __len__(self):
        return len(self.items)
    def __iter__(self):
        return self.items.__iter__()
    def accepts(self, value, slots: dict) -> dict | None:
        if len(value) < len(self.items):
            return None
        (rest, slots) = matches_set_helper(value, self.items, None, slots)
        if slots is None:
            return None
        if self.rest_name is None and self.rest_sub_pattern is None:
            return slots
        if self.rest_hook is not None:
            rest = self.rest_hook(rest)
        if self.rest_name is not None:
            slots = slots.copy()
            slots[self.rest_name] = rest
        if self.rest_sub_pattern is not None:
            return matches_pattern(rest, self.rest_sub_pattern, slots)
        return slots

def matches_set_helper(values, patterns, last_hook, slots: dict) -> tuple | None:
    n_patterns = len(patterns)
    if n_patterns == 0:
        return (values, slots)
    if n_patterns == 1 and last_hook is not None:
        return last_hook(values, patterns[0], slots)
    pattern = patterns[0]
    rest = patterns[1:]
    for (i, value) in enumerate(values):
        tmp_slots = matches_pattern(value, pattern, slots)
        if tmp_slots is None:
            continue
        retval = matches_set_helper([*values[:i], *values[(i + 1):]], rest, last_hook, tmp_slots)
        if retval[1] is not None:
            return retval
    return (None, None)

class PatternAny(PatternElement):
    def __hash__(self) -> int:
        return hash(())
    def __eq__(self, other) -> bool:
        return self is other or isinstance(other, PatternAny)
    def value_str(self) -> str:
        return '<*>'
    def accepts(self, value, slots: dict) -> dict | None:
        return slots

ANY = PatternAny()

def matches_base(value, pattern, slots: dict) -> dict | None:
    if has_method(pattern, 'canonicalize_pattern'):
        pattern = pattern.canonicalize_pattern()
    if has_method(value, 'matches'):
        return value.matches(pattern, slots)
    if has_method(value, '__iter__') and not isinstance(value, (str, bytes, bytearray)):
        if not has_method(pattern, '__iter__') or (has_method(value, '__len__') and has_method(pattern, '__len__') and len(value) != len(pattern)):
            return None
        for (sa, pa) in zip(value, pattern):
            slots = matches_pattern(sa, pa, slots)
            if slots is None:
                return None
        return slots
    return slots if value == pattern else None

def matches_pattern(value, pattern, slots: dict) -> dict | None:
    if slots is None:
        return slots
    if isinstance(pattern, PatternElement):
        return pattern.accepts(value, slots)
    return matches_base(value, pattern, slots)
