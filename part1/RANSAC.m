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






function [H, inliers] = RANSAC(it_max, matches, limiar_coli, limiar_inliers, nsuf_inliers)
    samples = 4;
    N = size(matches,1);
    best_n    = 0;
    best_mask = false(N, 1);
    best_H    = [];

    for i=1:it_max
        choices = randperm(N, samples); % Random com permutações que não usa as que já usou
        matches_i = matches(choices,:);
        
        % Teste de quasi-colinearidade
        if is_degenerate(matches_i, limiar_coli)
            continue;
        end

        % Computação da homography
        H_i = normalization_homography(matches_i(:,1:2), matches_i(:,3:4));

        % Calculo do numero de inliers que cada H_i tem nas várias matches
        pts_dst = matches(:,1:2); % referencia
        pts_src = matches(:,3:4);
        h_src = [pts_src, ones(N,1)]';
        h_est = H_i*h_src;
        pts_est = (h_est(1:2,:) ./ h_est(3, :))';
        err = sqrt(sum((pts_dest-pts_est)^2,2));
        mask = err < limiar_inliers;
        
        n = sum(mask); % Numero de inliers
        if n > best_n
            best_n    = n;
            best_mask = mask;
            best_H    = H;
        end
        if best_n >= nsuf_inliers
            break; %quebra o ciclo for
        end
    end
    
    % No caso de best_H estar vazio (improvável)
    if isempty(best_H)
        H = [];
        inliers = false(N, 1);
        return;
    end

    % Recomputação da melhor 
    inliers = best_mask;
    H = normalization_homography(matches(inliers, 1:2), matches(inliers, 3:4));
end

% O critério escolhido para avaliar a colinearidade entre 3 pontos da
% homografia é o seguinte: para v1 = p2 -
% p1 e v2 = p3 - p1, sendo sen(a)=|v1 x v2|/(||v1||.||v2||). Se sen(a)=±0,
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