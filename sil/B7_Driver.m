function [duty, veff_low, diag_cmd] = B7_Driver(low_L, low_R, high, position, drl, fog, blink_L, blink_R, brake, vbat, Ts, V_EFF, T_SOFT, POS_DIM, TAIL_DIM)
%#codegen
% B7 - Pilotage des sorties (PWM)
% duty (8 voies, %) : 1 croisement G, 2 croisement D, 3 route, 4 LED avant DRL/veilleuse,
%                     5 clignotant G, 6 clignotant D, 7 LED arriere stop/position, 8 antibrouillard AR
persistent ramp
if isempty(ramp), ramp = zeros(4,1); end         % rampes : croisement G, croisement D, route, antibrouillard

% 1) Regulation de tension des lampes halogenes : tension efficace constante = V_EFF
d_reg = min(1, (V_EFF / max(vbat, 1))^2);         % Veff = sqrt(duty) * Vbat

% 2) Demarrage progressif (soft-start) : limite le pic de courant du filament froid
req = [low_L; low_R; high; fog];
for i = 1:4
    if req(i)
        ramp(i) = min(ramp(i) + Ts / T_SOFT, 1);  % 0 -> 100 % en T_SOFT
    else
        ramp(i) = 0;                              % extinction immediate
    end
end
d = zeros(8,1);
d(1) = ramp(1) * d_reg;  d(2) = ramp(2) * d_reg;  d(3) = ramp(3) * d_reg;  d(8) = ramp(4) * d_reg;

% 3) LED avant a deux niveaux : DRL plein (100 %), veilleuse attenuee (REQ-LSC-05)
if drl
    d(4) = 1;
elseif position
    d(4) = POS_DIM;
end
% 4) Clignotants : pleine tension regulee des le 1er pas (pas de rampe, flash net)
d(5) = double(blink_L) * d_reg;  d(6) = double(blink_R) * d_reg;
% 5) LED arriere a deux niveaux : stop plein, position attenuee
if brake
    d(7) = 1;
elseif position
    d(7) = TAIL_DIM;
end

duty     = uint8(round(100 * d));
veff_low = sqrt(d(1)) * vbat;                     % tension efficace vue par le croisement gauche
diag_cmd = [d(1) > 0; d(2) > 0; d(5) > 0; d(6) > 0];   % lampes allumees, pour le diagnostic B6
