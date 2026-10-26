% main1.m atualizado com o Docker container mais apropriado para a extração
%  de features sem RANSAC ou outros processos - 9071
% Com o Docker instalado, e na pasta fleet do repo da cadeira, executar:
% docker compose up -d features (no cmd)

function main1(path_to_refdir, path_images_dir, path_feature_dir, path_output_dir)

    % Extrai as features de cada imagem e chama part1
    fprintf('refdir   : %s\n', path_to_refdir); % Pasta da imagem de referência
    fprintf('imagens  : %s\n', path_images_dir); % Pasta das imagens a mudar o plano
    fprintf('features : %s\n', path_feature_dir); % Pasta dos features de cada imagem
    fprintf('output   : %s\n', path_output_dir); % Pasta do output

    % Verificação das imagens
    files = dir(fullfile(path_images_dir, '*.jpg'));
    if isempty(files)
        error('Sem ficheiros .jpg em %s', path_images_dir);
    end
    fprintf('%d imagens, de %s a %s\n', numel(files), files(1).name, files(end).name);

    % --- Configuração do VisionIST (Porta 9071 - features, mais rápida que a 9065) ---
    cfg = vsConfig();
    cfg.python = '"C:\Users\José Bernardo\AppData\Local\Python\pythoncore-3.14-64\python.exe"';
    cfg.hosts.features = "127.0.0.1:9071";
    cfg.verbose = 0; % Evita que cada iteração seja impressa
    
    % Inicializar o cliente apontado para o container de features
    b = py.visionist_client.Visionist(cfg.hosts.features);
    
    % Verificação da pasta dir
    if ~exist(path_feature_dir, 'dir')
        mkdir(path_feature_dir);
    end
    
    % Teste das pastas das imagens 
    ref = dir(fullfile(path_to_refdir, 'templateimg.jpg'));
    if isempty(ref)
        error('Sem ficheiros .jpg em %s', path_to_refdir);
    end
    files = dir(fullfile(path_images_dir, '*.jpg'));
    if isempty(files)
        error('Sem ficheiros .jpg em %s', path_images_dir);
    end
    
    % Extração dos keypoints
    max_kp = 2000;
    dim = length(files);
    
    % A referência é a primeira imagem
    extrair_keypoints(ref, max_kp, path_feature_dir, b);

    % Todas as outras imagens no loop
    for k = 1:dim
       extrair_keypoints(files(k), max_kp, path_feature_dir, b);    
    end
    
    % Chamar o part1.m
    part1(path_to_refdir, path_images_dir, path_feature_dir, path_output_dir)

end


function extrair_keypoints(entry, max_kp, path_recording, b)
    img_path = fullfile(entry.folder, entry.name);
    
    % Configuração do container das features
    features_params = py.dict();
    py_config = py.dict(struct('features', features_params));

    % O container espera uma lista de imagens
    img_list = py.list({py.pathlib.Path(img_path)});
    py_data = py.dict(struct('images', img_list));

    % Correr o container 9071
    res_feat = b.run(data=py_data, config=py_config);

    % Os arrays vêm em numpy arrays - necessário convertê-los
    keypoints_raw = double(py.numpy.array(res_feat.fields{'keypoints'}));
    counts = double(py.numpy.array(res_feat.fields{'counts'}));

    % Formato dos arrays devolvidos:
    %  keypoints = (num_images, 2 + 128, N)
    %  countes = (num_images, )

    % Como o container é executado com apenas 1 imagem de cada vez,
    % o primeiro valor do array de keypoints é sempre 1

    % O primeiro valor do counts corresponde ao número de keypoints real,
    % que é usado para fazer o slicing
    N_1 = int32(counts(1));

    % (N_1, 2) = pontos
    xy  = squeeze(keypoints_raw(1, 1:2, 1:N_1))';

    % (N_1, 128) = descriptors
    des = squeeze(keypoints_raw(1, 3:end, 1:N_1))';
    
    % Necessário manter o formato por causa do part1.m
    keypoints  = [xy'; des']; 

    [~, name] = fileparts(entry.name);  % Nome sem a extensão
    save(fullfile(path_recording, [name '.mat']), 'keypoints', '-v7');
end
