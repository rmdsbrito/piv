function part1(path_to_refdir, path_images_dir, path_feature_dir, path_output_dir)
    
    % Dar load aos features resultantes da main1
    features_entry = dir(fullfile(path_feature_dir,'*.mat'));
    ref_entry = dir(fullfile(path_feature_dir, 'templateimg.mat'));
    
    kp_ref = load_entry(ref_entry);

    for k = 1:length(features_entry)
        feat_i = load_entry(features_entry(k));
    end
end

function [kp] = load_entry(entry)
    entry_path = fullfile(entry.folder, entry.name);
    s = load(entry_path);
    disp(size(s.kp));
    kp = s.kp;
end