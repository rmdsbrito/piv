function [H, valid, n_inl, modo] = track_sequence(feats, feat_ref, params)
% TRACK_SEQUENCE  Homografia de cada frame de uma sequência para a referência.
%
%   [H, valid, n_inl, modo] = track_sequence(feats, feat_ref, params)
%
%   Entradas
%     feats     cell 1xN; feats{i} = kp do frame i (130 x n_i), no formato
%               do enunciado: linhas 1-2 = (x, y), linhas 3-130 = descritor
%     feat_ref  kp da imagem de referência, mesmo formato
%     params    struct; todos os campos são opcionais
%
%   Saídas
%     H      3x3xN; H(:,:,i) leva píxeis do frame i para a referência
%     valid  1xN logical; false nos frames sem estimativa fiável
%            (nesses frames H(:,:,i) repete a última H válida)
%     n_inl  1xN; nº de inliers da estimativa escolhida em cada frame
%     modo   1xN; 1 = direto à referência, 2 = frame a frame, 0 = falhou
%
%   Estratégia (por omissão: direto à referência, com frame a frame
%   como recurso, porque foi onde os testes me deram melhores resultados)*
%     1. Direto à referência: emparelha o frame i com a referência. Não
%        acumula erro (drift), por isso é a opção preferida sempre que há
%        inliers suficientes. Tenta-se de 'reanchor_every' em
%        'reanchor_every' frames (por omissão: em todos) e sempre que o
%        frame anterior falhou (p.ex. depois de um corte).
%     2. Frame a frame (recurso): se o direto não foi tentado ou falhou
%        (exemplo: câmara muito longe da referência ou campo meio 
%        fora da imagem), emparelha o frame i com o i-1 e compõe:
%            H(i->ref) = H(i-1->ref) * H(i->i-1)
%        Frames seguidos têm sempre muitos matches; o preço disso é o
%        drift.
%     3. Se nenhuma das duas tiver pelo menos 'min_inliers' inliers, o
%        frame é marcado como inválido (close-up, público, replay...).
%
%   *- Só testei o clip1 do game1 do TrackNet que era com camera parada,
%   por isso convem testar com outros frames depois para ver se direto 
%   da referência continua a compensar ou não.
%
%   Casos particulares úteis para comparar estratégias
%     reanchor_every = 1   -> direto sempre que possível (omissão)
%     reanchor_every = 10  -> híbrida: frame a frame, re-ancora de 10 em 10
%     reanchor_every = Inf -> frame a frame "puro" (só volta à referência
%                             quando o frame a frame falha)
%
%   Parâmetros (params.<nome>, valor por omissão)
%     it_max          500    iterações do RANSAC
%     limiar_coli     0.05   limiar de quase-colinearidade (seno do ângulo)
%     limiar_inliers  3      erro máximo (px) para um match ser inlier
%     nsuf_inliers    Inf    RANSAC pára cedo se atingir este nº de inliers
%     min_inliers     30     mínimo de inliers para aceitar uma homografia
%     reanchor_every  1      de quantos em quantos frames tenta a referência
%     match_fn        []     (vazio = matching provisório do matching_H)
%                            função matches = f(kp_dst, kp_src) que devolve
%                            [x_dst y_dst x_src y_src] (convenção do RANSAC)
%
%   Usa: matching_H.m (matching + RANSAC entre duas imagens).

if nargin < 3, params = struct(); end
p.it_max         = get_param(params, 'it_max', 500);
p.limiar_coli    = get_param(params, 'limiar_coli', 0.05);
p.limiar_inliers = get_param(params, 'limiar_inliers', 3);
p.nsuf_inliers   = get_param(params, 'nsuf_inliers', Inf);
p.min_inliers    = get_param(params, 'min_inliers', 30);
p.reanchor_every = get_param(params, 'reanchor_every', 1);
p.match_fn       = get_param(params, 'match_fn', []);   % vazio = o matching_H usa o provisório

N     = numel(feats);
H     = repmat(eye(3), 1, 1, N);
valid = false(1, N);
n_inl = zeros(1, N);
modo  = zeros(1, N);

H_ultima = eye(3);                 % última H válida (frame -> referência)

for i = 1:N
    H_ff  = [];  inl_ff  = 0;
    H_dir = [];  inl_dir = 0;

    % 1) Direto à referência, quando está programado: 1º frame, de
    %    'reanchor_every' em 'reanchor_every' frames, ou se o anterior falhou
    programado = (i == 1) || mod(i-1, p.reanchor_every) == 0 || ~valid(i-1);
    if programado
        % dst = referência, src = frame i  ->  leva o frame i à referência
        [H_dir, inl_dir] = matching_H(feat_ref, feats{i}, p);
    end

    % 2) Frame a frame, se o direto não deu (só se o anterior foi válido)
    if isempty(H_dir) && i > 1 && valid(i-1)
        % dst = frame i-1, src = frame i  ->  H_loc leva o frame i ao i-1
        [H_loc, inl_ff] = matching_H(feats{i-1}, feats{i}, p);
        if ~isempty(H_loc)
            H_ff = H(:,:,i-1) * H_loc;
        end
    end

    % 2b) Último recurso: direto à referência, se ainda não foi tentado
    if isempty(H_dir) && isempty(H_ff) && ~programado
        [H_dir, inl_dir] = matching_H(feat_ref, feats{i}, p);
    end

    % 3) Escolha: o direto tem prioridade porque não acumula erro
    if ~isempty(H_dir)
        H(:,:,i) = normaliza(H_dir);
        n_inl(i) = inl_dir;  modo(i) = 1;  valid(i) = true;
    elseif ~isempty(H_ff)
        H(:,:,i) = normaliza(H_ff);
        n_inl(i) = inl_ff;   modo(i) = 2;  valid(i) = true;
    else
        H(:,:,i) = H_ultima;                    % frame inválido
        n_inl(i) = max(inl_ff, inl_dir);
    end

    if valid(i)
        H_ultima = H(:,:,i);
    end
end
end


function H = normaliza(H)
% Mesma normalização que o resto do código (escala arbitrária).
H = H ./ max(abs(H(:)));
end


function v = get_param(params, nome, omissao)
if isfield(params, nome) && ~isempty(params.(nome))
    v = params.(nome);
else
    v = omissao;
end
end
