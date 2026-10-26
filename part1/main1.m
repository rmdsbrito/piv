function main1(path_to_refdir, path_images_dir, path_feature_dir, path_output_dir)
    % Extrai as features de cada imagem e chama part1.
    
    fprintf('refdir   : %s\n', path_to_refdir); % Pasta da imagem de referência
    fprintf('imagens  : %s\n', path_images_dir); % Pasta das imagens a mudar o plano
    fprintf('features : %s\n', path_feature_dir); % Pasta dos features de cada imagem
    fprintf('output   : %s\n', path_output_dir); % Pasta do output
    
    files = dir(fullfile(path_images_dir, '*.jpg'));
    if isempty(files)
        error('Sem ficheiros .jpg em %s', path_images_dir);
    end
    fprintf('%d imagens, de %s a %s\n', numel(files), files(1).name, files(end).name);

    % --- configuração da box (específica da tua máquina) ---
    cfg = vsConfig();
    cfg.python = "/home/rodrigobrito/venvs/piv/bin/python";
    cfg.hosts.opencv = "127.0.0.1:9065";
    cfg.verbose = 0; % Evita que cada iteração seja imprimia
    
    if ~exist(path_feature_dir, 'dir')
        mkdir(path_feature_dir);
    end
    
    % --- Teste das pastas das imagens ---
    ref = dir(fullfile(path_to_refdir, 'templateimg.jpg'));
    if isempty(ref)
        error('Sem ficheiros .jpg em %s', path_to_refdir);
    end
    files = dir(fullfile(path_images_dir, '*.jpg'));
    if isempty(files)
        error('Sem ficheiros .jpg em %s', path_images_dir);
    end
    
    % --- Extração dos keypoints da imagem de referência ---
    max_kp = 2000;
    dim = length(files);
    
    extrair_keypoints(ref, max_kp, path_feature_dir, cfg); % A referência é a primeira imagem
    for k = 1:dim
       extrair_keypoints(files(k),max_kp, path_feature_dir, cfg);    
    end
    
    % --- Chamada do part1.m ---
    
    part1(path_to_refdir, path_images_dir, path_feature_dir, path_output_dir)

end


function extrair_keypoints(entry, max_kp, path_recording, cfg)
    img_path = fullfile(entry.folder, entry.name);
    out = vsOpencv(cfg, 'images', string(img_path), ...
        'feature_extractor', "SIFT", 'max_keypoints', max_kp);
    xy  = squeeze(out.keypoints);          % n x 2
    des = squeeze(out.descriptors);        % n x 128
    kp  = [xy'; des']; 

    [~, name] = fileparts(entry.name);  % nome sem a extensão
    save(fullfile(path_recording, [name '.mat']), 'kp', '-v7');

end