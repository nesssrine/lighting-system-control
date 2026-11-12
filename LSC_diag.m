function [fault_act, dtc_stored, degraded, warning] = LSC_diag(lamp_cmd, lamp_cur, clear_dtc)
%#codegen
% RUNNABLE 2 (10 ms) du calculateur d'eclairage : B6 diagnostic des lampes
P = LSC_params_const();
[fault_act, dtc_stored, degraded, warning] = B6_Diag(lamp_cmd, lamp_cur, clear_dtc, ...
    P.Ts, P.I_NOM, P.R_OPEN, P.R_SHORT, P.T_INRUSH, P.T_CONF, P.T_HEAL);
