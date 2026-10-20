% TESTE 1

H_true = [1  2  3;
          2 -1  4;
          3  1  2];

p = [1, 2;
        7, 20;
        31, 2;
        15, 15];

p_tr_hom = H_true * [p'; ones(1,4)];
p_tr = p_tr_hom(1:2, :) ./ p_tr_hom(3, :);
p_tr = p_tr';

H = normalization_homography(p_tr, p);
disp(H);


% TESTE 2
p = rand(50, 2);

p_tr_hom = H_true * [p'; ones(1,50)];
p_tr = p_tr_hom(1:2, :) ./ p_tr_hom(3, :);
p_tr = p_tr';
rmse = 0;
H_av = zeros(3,3);
for i=1:200
    p_tr_n = p_tr + randn(50,2);
    H_i = normalization_homography(p_tr_n, p);
    rmse = rmse + sqrt(mean((H_i(:) - H(:)).^2));
    H_av = H_av + abs(H_i);
end

H_av = H_av/200;
disp(H_av);
disp(rmse);