function part1(path_to_refdir, path_images_dir, path_feature_dir, path_output_dir)
        
    % Obter todos os ficheiros de features na pasta path_feature_dir
    features = dir(fullfile(path_feature_dir, '*.mat'));
    
    % Parâmetros do RANSAC - ajustar depois
    it_max = 1000;
    limiar_coli = 0.05; % Limite para o teste de quasi-colinearidade
    limiar_inliers = 3.0; % Limite de erro em pixels para se poder considerar inlier
    nsuf_inliers = 200; % Número suficiente de inliers para se poder parar

    % Features da imagem de referência (templateimg.mat na pasta path_to_refdir)
    reference = dir(fullfile(path_feature_dir, 'templateimg.mat'));

    kp_ref = load_entry(reference);
    xy_ref  = kp_ref(1:2, :)'; % Coordenadas da referência (N x 2)
    desc_ref = kp_ref(3:end, :)'; % Descritores da referência (N x 128)

    % Loop para todas as outras imagens
    for k = 1:length(features)
        filename = features(k).name;
        
        % Ignorar a referência
        if strcmp(filename, 'templateimg.mat')
            continue;
        end
        
        [~, name_only] = fileparts(filename);
        
        % Carregar as features da imagem atual
        feat_i = load_entry(features(k));
        xy_i  = feat_i(1:2, :)';
        desc_i = feat_i(3:end, :)';
        
        % Matching usando o matchFeatures (se for preciso implementa-se à mão)
        pairs = matchFeatures(desc_ref, desc_i, 'Unique', true, 'MaxRatio', 0.8);
        
        % É necessário 4 pontos para uma homografia - se não forem encontrados
        % 4 matches, coloquei só a identidade (deve ser importante mudar para o
        % ponto 6)
        if size(pairs, 1) < 4
            warning('Poucas correspondências encontradas para o frame %s', name_only);
            H = eye(3);
            Hc = eye(3);
        else

            % Matriz de matches para o  RANSAC - [pts_ref_x, pts_ref_y, pts_i_x, pts_i_y]
            pts_ref_matched = xy_ref(pairs(:, 1), :);
            pts_i_matched   = xy_i(pairs(:, 2), :);
            matches = [pts_ref_matched, pts_i_matched];
            
            % RANSAC
            [H, inliers] = RANSAC(it_max, matches, limiar_coli, limiar_inliers, nsuf_inliers);
            Hc = eye(3); % Temporário!
            
            if isempty(H)
                H = eye(3);
            end
        end
        
        % Guardar o output - {"H": H, "Hc": Hc} no ficheiro homography_NNNN.mat
        output_filename = ['homography_', name_only(end-3:end), '.mat'];
        save(fullfile(path_output_dir, output_filename), 'H', 'Hc', '-v7');
    end
end

function [kp] = load_entry(entry)
    entry_path = fullfile(entry.folder, entry.name);
    s = load(entry_path);
    kp = s.kp;
end