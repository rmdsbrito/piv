% TESTE 1

H_true = [1  2  3;
          2 -1  4;
          3  1  2];

ptos = [1, 2;
        7, 20;
        31, 2;
        15, 15];

ptostr_hom = H_true * [ptos'; ones(1,4)];
ptostr = ptostr_hom(1:2, :) ./ ptostr_hom(3, :);
ptostr = ptostr'; % Matriz Nx2 com os pontos transformados

points = [ptostr, ptos];

H = homography(points);
disp(H);

% TESTE 2
ptosB = rand(50, 2);

ptostr_homB = H_true * [ptosB'; ones(1,50)];
ptostrB = ptostr_homB(1:2, :) ./ ptostr_homB(3, :);
ptostrB = ptostrB'; % Matriz Nx2 com os pontos transformados

pointsB = [ptostrB, ptosB];

HB = homography(pointsB);
disp(HB)