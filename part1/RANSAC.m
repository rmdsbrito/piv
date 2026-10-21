% Neste algoritmo encontra-se implementado o RANSAC ou RAndom SAmple
% Consensus. O objetivo é, após o matching the pares entre imagens com o
% SIFT, filtrar os outliers

% O racíocinio a seguir será os seguinte (retirado dos slides de PIV):
% 1. Randomly choose s samples
%   • Typically n = minimum sample size that lets you fit a model (4 neste caso)
% 2. Fit a model (homography) to those samples
% 3. Count the number of inliers that approximately fit the
% model
% 4. Repeat N times
% 5. Choose the model that has the largest set of inliers






function [H, inliers] = RANSAC(it_max, matches, limiar_coli, limiar_ransac, nsuf_inliers)
    samples = 4;
    n_samples = size(matches,1);
    v_inliers = zeros(it_max);
    v_H = zeros(it_max);

    for i=1:it_max
        choices = randperm(n_samples, samples); % Random com permutações que não usa as que já usou
        matches_i = matches(choices,:);
        notmatches_i = matches(setdiff(1:size(matches,1), choices), :);

        % Teste de quasi-colinearidade
        if is_degenerate(matches_i, limiar_coli)
            continue;
        end

        % Computação da homography
        H_i = normalization_homography(matches_i(:,1:2), matches_i(:,3:4));


        pts1 = matches(:,1:2); % referencia
        pts2 = matches(:,3:4);
        hpts2 = [pts2, ones(n_samples,1)]';
        hpts_est = H_i*hpts2;
        pts_est = [hpts_est(1,j)/ hpts_est(3,j)  hpts_est(2,j)/hpts_est(3,j)];
        inl = 0;
        
        for j=1:n_samples
            err = sqrt((pts1(1) - pts_est(1))^2+((pts1(j,2) - pts_est(j,2))^2));
            if err < limiar_ransac 
                inl = inl + 1;
            end
            if inl >= nsuf_inliers
                break;
            end
            
        end
        v_inliers(i) = inl;
        v_H(i) = H_i;
    end
    inliers = max(v_inliers);
    H = max(v_H);
end

% O critério escolhido para avaliar a colinearidade entre 3 pontos da
% homografia é o seguinte: para v1 = p2 -
% p1 e v2 = p3 - p2, sendo sen(a)=|v1 x v2|/(||v1||.||v2||). Se sen(a)=±0,
% então os pontos são quase colineares e a homografia calculada deve ser
% descartada

function cond = is_degenerate(points, limiar)
    cond = false;
    choices = nchoosek(1:4, 3);
    for i = 1:size(choices, 1)
         choice = choices(i, :);
        if sin_criteria(points(choice, 1:2), limiar) || ...
                sin_criteria(points(choice, 3:4), limiar)
            cond = true;
            return
        end
    end
end 

function cond = sin_criteria(p, limiar)
    v1 = p(2, :) - p(1, :);
    v2 = p(3, :) - p(1, :);
    cr  = v1(1)*v2(2) - v1(2)*v2(1);   % igual a det([p 1]) a menos de sinal
    den = norm(v1) * norm(v2);
    cond = (den == 0) || (abs(cr) / den < limiar);
end