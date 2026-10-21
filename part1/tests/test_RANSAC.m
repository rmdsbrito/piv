matches = [1 2 4 5; 3 4 2 1; 2 3 1 7; 1 5 8 1; 9 2 11 4; 1 17 1 1];

it_max = 200;
limiar_coli = 1;
limiar_ransac = 0.5;

[H, inliers] = RANSAC(it_max, matches, limiar_coli, limiar_ransac);

