%% Teste para as imagens do dataset "ireland" que está na drive

% Pasta onde este script está guardado
[script_dir, ~, ~] = fileparts(mfilename('fullpath'));
test_dir = fullfile(script_dir, 'Path_Folders');

% Caminhos exigidos pelo main1
path_to_refdir = fullfile(test_dir, 'path_to_refdir');
path_images_dir = fullfile(test_dir, 'path_images_dir');
path_feature_dir = fullfile(test_dir, 'path_feature_dir');
path_output_dir = fullfile(test_dir, 'path_output_dir');

% Executar o main1
main1(path_to_refdir, path_images_dir, path_feature_dir, path_output_dir);


%% Visualização

% Referência
ref_img_path = fullfile(path_to_refdir, 'templateimg.jpg');
ref_img = imread(ref_img_path);

% Dimensões da imagem de referência
[ref_h, ref_w, ~] = size(ref_img);

% Ficheiros de homografia guardados
homog_files = dir(fullfile(path_output_dir, 'homography_*.mat'));

% Criar a figura (referência à esquerda, transformada à direita)
figure('Name', 'Validação Visual de Homografias', 'Position', [100, 100, 1000, 500]);

for k = 1:numel(homog_files)

    % Carregar a homografia H do frame k
    hom_path = fullfile(path_output_dir, homog_files(k).name);

    % Homografia do frame para a referência
    data = load(hom_path);
    H = data.H;

    % homography_NNNN.mat corresponde a somename_NNNN.jpg
    [~, h_name] = fileparts(homog_files(k).name);
    frame_num_str = extractAfter(h_name, 'homography_');

    % Procurar a imagem correspondente na pasta de imagens
    img_match = dir(fullfile(path_images_dir, ['*_' frame_num_str '.jpg']));

    % Obter os caminhos das imagens
    current_img_path = fullfile(img_match(1).folder, img_match(1).name);
    current_img = imread(current_img_path);

    % Objeto de referência que especifica o tamanho da imagem
    ref_vision = imref2d([ref_h, ref_w]);

    % A homografia é transformada no objeto do matlab que serve para fazer
    % o imwarp
    tform = projective2d(H');

    % Aplicar a homografia usando imwarp
    warped_img = imwarp(current_img, tform, 'OutputView', ref_vision);

    % Comparação lado a lado
    subplot(1, 2, 1);
    imshow(ref_img);
    title('Imagem de Referência (templateimg.jpg)');

    subplot(1, 2, 2);
    imshow(warped_img);
    title(sprintf('Frame %s deformado para a Referência', frame_num_str));

    drawnow;
    pause(0.2);
end
