function x = g711_decode(code, mu)
    if nargin < 2, mu = 255; end
    y = double(code)/255 * 2 - 1;
    x = sign(y) .* (1/mu) .* ((1 + mu).^abs(y) - 1);
end
