N = 3;
P = 0.824;
% P = [0.875	0.9583	0.9999	0.9999	0.9999	0.916667	0.9167	0.916667	0.9999	0.625	0.416667	0.833333	0.625];
duration = 1.5;
C = 60/duration;

ITR = (log2(N)+P.*log2(P)+(1-P).*log2((1-P)./(N-1)))*C;

mean(ITR)
