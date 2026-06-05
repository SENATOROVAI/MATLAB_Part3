function code = g711_encode(x, mu)
    if nargin < 2, mu = 255; end
    x = max(min(x(:), 1), -1);
    y = sign(x) .* log(1 + mu*abs(x)) / log(1 + mu);
    code = uint8(round((y + 1) / 2 * 255));
end
