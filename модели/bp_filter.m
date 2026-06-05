function y = bp_filter(x, fs, f_low, f_high, order)
    if nargin < 5, order  = 4;    end
    if nargin < 4, f_high = 3400; end
    if nargin < 3, f_low  = 300;  end
    x = x(:);
    has_butter = (exist('butter','file') == 2) && license('test','signal_toolbox');
    if has_butter
        [b, a] = butter(order, [f_low f_high]/(fs/2), 'bandpass');
        y = filter(b, a, x);
    else
        y = local_fft_bandpass(x, fs, f_low, f_high);
    end
end

function y = local_fft_bandpass(x, fs, f_low, f_high)
    N = numel(x);
    X = fft(x);
    f = (0:N-1)'/N * fs;
    f(f > fs/2) = f(f > fs/2) - fs;
    fa = abs(f);
    trans = min([50, f_low/2, (f_high - f_low)/2]);
    H = double(fa >= f_low & fa <= f_high);
    lo = fa >= (f_low - trans) & fa < f_low;
    hi = fa >  f_high & fa <= (f_high + trans);
    H(lo) = 0.5 - 0.5*cos(pi*(fa(lo) - (f_low - trans))/trans);
    H(hi) = 0.5 + 0.5*cos(pi*(fa(hi) - f_high)/trans);
    y = real(ifft(X .* H));
end
