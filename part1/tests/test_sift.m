%% Teste com SIFT para duas imagens
% Necessário ter o docker com o container 9065 a correr
% Instalar o docker, clonar a VisionIST, e dentro da pasta "fleet" executar
% na cmd: docker run --rm -p 9065:8061 -e PORT=8061 sipgisr/visionist-opencv:latest
% Só depois dá para correr este ficheiro
% Meti imagens minhas na /images e está a correr bem


%% Caminhos e imagens

% A pasta correta é a SIFT_test
projectDir = pwd;

% Se não estivermos na pasta correta, manda mensagem com a pasta atual
assert(isfile(fullfile(projectDir, "sift_test.m")), "O diretório atual não parece ser a raiz de SIFT_test: %s", projectDir);

% Pasta que contém os ficheiros vsX (matlab, default do repo do prof)
matlabDir = fullfile(projectDir, "matlab");

% Adicionar as funções ao path
addpath(matlabDir);

% Caminhos das imagens (fotos minhas na /images)
img_left  = fullfile(projectDir, "/images/left.jpg");
img_right = fullfile(projectDir, "/images/right.jpg");

% Se as imagens não forem encontradas
assert(isfile(img_left), "Ficheiro não encontrado: %s", img_left);
assert(isfile(img_right), "Ficheiro não encontrado: %s", img_right);


%% Configuração

cfg = vsConfig();
cfg.session_id = "sift-matching-session";
cfg.hosts.opencv = "127.0.0.1:9065";

fprintf("Projeto: %s\n", projectDir);
fprintf("Config: %s\n", matlabDir);
fprintf("Python: %s\n", cfg.python);
fprintf("Session: %s\n", cfg.session_id);
fprintf("Host: %s\n", cfg.hosts.opencv);


%% Pipeline

b = py.visionist_client.Visionist(cfg.hosts.opencv);

% Dados e parâmetros
img_list = py.list({py.pathlib.Path(img_left), py.pathlib.Path(img_right)});
py_data = py.dict(struct('images', img_list));

params = py.dict(struct('feature_extractor', 'SIFT', 'max_keypoints', 1000, 'ratio_thresh', 0.75));
opencv_conf = py.dict(struct('command', 'match', 'parameters', params));
py_config = py.dict(struct('opencv', opencv_conf));

% Executar
res = b.run(data=py_data, config=py_config);

% Extrair resultados usando os campos do framework
pts_a = double(py.numpy.array(res.fields{'matches_inliers_a'}));
pts_b = double(py.numpy.array(res.fields{'matches_inliers_b'}));
F = double(py.numpy.array(res.fields{'fundamental_matrix'}));

fprintf("\nEncontrados %d inliers.\n", size(pts_a, 1));
disp("Matriz Fundamental F:");
disp(F);

%% Visualização

left_img  = imread(img_left);
right_img = imread(img_right);
canvas = cat(2, left_img, right_img);
offset = size(left_img, 2);

figure();
imshow(canvas);
hold on;

% Linhas e pontos para cada inlier
for i = 1:size(pts_a, 1)
    xa = pts_a(i, 1);
    ya = pts_a(i, 2);
    xb = pts_b(i, 1) + offset;
    yb = pts_b(i, 2);

    plot([xa, xb], [ya, yb], 'g-', 'LineWidth', 1);
    plot(xa, ya, 'ro', 'MarkerSize', 3, 'MarkerFaceColor', 'r');
    plot(xb, yb, 'ro', 'MarkerSize', 3, 'MarkerFaceColor', 'r');
end
hold off;

saveas(gcf, 'matches.jpg');
disp("Imagem gravada com sucesso.")
