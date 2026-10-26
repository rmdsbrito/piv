function [H_ref2court, idx, px] = anchoring(path_to_refdir)
    % carrega a data do path_to_refdir
    cm  = load(fullfile(path_to_refdir, 'courtmodel.mat'));
    pts = cm.pts;
    img = imread(fullfile(path_to_refdir, 'templateimg.png'));
    N   = size(pts, 1);
    
    % mostra a imagem
    figure; imshow(img); hold on;
    idx = []; px = [];
    for k = 1:N
        title(sprintf('Clica em: %s (%d/%d)  |  botão direito = não visível', ...
              get_name(cm.names, k), k, N));
        [x, y, b] = ginput(1);
        if b == 3, continue; end
        plot(x, y, 'r+', 'MarkerSize', 12);
        idx(end+1) = k;
        px(end+1,:) = [x y];
    end
    % pelo menos 4 pontos necessários - não faz verificação de
    % colinearidade
    assert(numel(idx) >= 4, 'São precisos pelo menos 4 pontos.');

    % cálculo da âncora
    H_ref2court = normalization_homography(pts(idx,:), px);

    % aplicar homografia nos pontos selecionados e ver se correspondem aos
    % do campo
    p  = H_ref2court * [px, ones(size(px,1),1)]';
    pe = (p(1:2,:) ./ p(3,:))';
    err = sqrt(sum((pe - pts(idx,:)).^2, 2));
    fprintf('Erro nos landmarks: mediana %.3f m, máx %.3f m\n', median(err), max(err));

    q  = H_ref2court \ [pts, ones(N,1)]';
    qi = (q(1:2,:) ./ q(3,:))';
    plot(qi(:,1), qi(:,2), 'g.', 'MarkerSize', 15);
end

function s = get_name(names, k)
    if iscell(names),        s = char(names{k});
    elseif isstring(names),  s = char(names(k));
    else,                    s = strtrim(names(k,:));
    end
end