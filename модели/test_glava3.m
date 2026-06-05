function test_glava3
    test_bp_filter();
    test_g711();
    test_alarm_fsm();
    test_formulas();
    fprintf('ALL TESTS PASSED\n');
end

function test_bp_filter
    fs = 8000; t = (0:fs-1)'/fs;
    x = sin(2*pi*150*t) + sin(2*pi*1000*t) + sin(2*pi*3800*t);
    y = bp_filter(x, fs, 300, 3400, 4);
    P = @(s,f) abs(sum(s.*exp(-1j*2*pi*f*t)))/numel(s);
    assert(P(y,1000) > 0.3, 'bp_filter: внутриполосный тон 1000 Гц подавлен');
    assert(P(y,150)  < 0.10, 'bp_filter: тон 150 Гц не подавлен');
    assert(P(y,3800) < 0.10, 'bp_filter: тон 3800 Гц не подавлен');
    fprintf('  test_bp_filter OK\n');
end

function test_g711
    x = 0.5*sin(2*pi*(0:999)'/50);
    code = g711_encode(x);
    assert(isa(code,'uint8'), 'g711_encode: тип кода не uint8');
    xr = g711_decode(code);
    snr = 10*log10(sum(x.^2) / sum((x - xr).^2));
    assert(snr > 30, sprintf('g711: SNR %.1f дБ < 30', snr));
    fprintf('  test_g711 OK (SNR %.1f дБ)\n', snr);
end

function test_alarm_fsm
    ev(1) = struct('time', 1.0, 'type', 'fire');
    ev(2) = struct('time', 3.0, 'type', 'reset');
    [ts, st] = alarm_fsm(ev, 100);
    i1 = find(ts >= 1.0, 1);
    i2 = find(ts >= 2.0, 1);
    assert(st(i1) == 2, 'alarm_fsm: после fire ожидается ALARM');
    assert(st(i2) == 3, 'alarm_fsm: через 0.5 c ожидается EVACUATION');
    assert(st(end) == 1, 'alarm_fsm: после reset ожидается IDLE');
    fprintf('  test_alarm_fsm OK\n');
end

function test_formulas
    Pt = 20; Gt = 5; Gr = 3; L = 80; L_fade = 5;
    Pr = Pt + Gt + Gr - L - L_fade;
    assert(Pr == -57, sprintf('Pr = %g, ожидалось -57', Pr));
    sensitivity = 95; inputPower = 10; distance = 10;
    SPL = sensitivity + 10*log10(inputPower) - 20*log10(distance);
    assert(abs(SPL - 85) < 1e-9, sprintf('SPL = %g, ожидалось 85', SPL));
    fprintf('  test_formulas OK (Pr=%d дБм, SPL=%d дБ)\n', Pr, SPL);
end
