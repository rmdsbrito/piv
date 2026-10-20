% Temos que fazer uma minimização do estilo. min ||Ah||² s.t. ||h|| = 1
% Com lagrange ficamos com L(h, lambda) = h'A'Ah - lambda*(h'h - 1).
% Fazendo d/dh L = 0, ficamos com A'Ah = lambda*h, de que resulta que as
% solulões serão os vetores próprios de A'A. Para minimizar temos 
% h = V(:,end)'

function [H] = homography(p_tr, p) % Deve ser uma matriz [x1_tr y1_tr x1 y1; ...]
N = size(p_tr,1);
A = zeros(2*N, 9);
for i=1:N
    x_tr = p_tr(i,1);
    y_tr = p_tr(i,2);
    x = p(i,1);
    y = p(i,2);
    A(2*i-1, :)  = [-x -y -1  0  0  0 x_tr*x x_tr*y x_tr];
    A(2*i, :)    = [ 0  0  0 -x -y -1 y_tr*x y_tr*y y_tr];
end
% V para A'A e para A é igual (A'A = V'sig²V)
[~, ~, V] = svd(A'*A, 0);
H = reshape(V(:, end), 3, 3)';
H = H ./ max(abs(H(:))); % Assim é possível normalizar sem ter o problema de h33 ser quase 0 
end