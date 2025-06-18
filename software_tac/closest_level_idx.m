function idx = closest_level_idx(val, levels)
    [~, idx] = min(abs(levels - val));
end