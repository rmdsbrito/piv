function [H] = normalization_homography(p_tr, p)
% Normalização dos dados antes de calcular a homografia
[p_tr_hat, T_tr] = normalization(p_tr);
[p_hat, T] = normalization(p);

% Calculo da Homografia normalizada
H_hat = homography(p_tr_hat, p_hat);

% Calculo da Homografia direta
H = T_tr \ H_hat * T;
H = H ./ max(abs(H(:)));
end

% Esta função serve para normalizar os pontos antes de obter a homografia,
% de modo a que os pontos mais afastados não tenham um peso demasiado
% significativo no calculo da homografia

function [p_hat, T] = normalization(p)
cx = mean(p(:,1));
cy = mean(p(:,2));
d = mean(sqrt((p(:,1) - cx).^2 + (p(:,2) - cy).^2));
p_hat = [(p(:,1) - cx), (p(:,2) - cy)] * (sqrt(2)/d);

trans = [1  0 -cx;
        0  1 -cy;
        0  0  1 ];

s = (sqrt(2)/d);
scale = [s 0 0;
         0 s 0;
         0 0 1];

T = scale * trans;
end
