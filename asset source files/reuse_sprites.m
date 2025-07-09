function reuse_sprites(anim_name, n_angles, n_frames, threshold)

for j = 1:n_angles
    for i = 1:n_frames
        
        filename1 = sprintf("col/%s%03d_col_%02d.png", anim_name, i, j)
        [cdata1 ,~ ,alpha1] = imread(filename1);
        for k = i+1:n_frames
            filename2 = sprintf("col/%s%03d_col_%02d.png", anim_name, k, j);
            [cdata2 ,~ ,alpha2] = imread(filename2);
            aDiff = abs(alpha1-alpha2);
            cDiff = abs(cdata1-cdata2);
            maxDiff = max(max(aDiff(:)), max(cDiff(:)));
            if maxDiff <= threshold
                maxDiff
                imwrite(cdata1, filename2, "Alpha", alpha1);
                filename3 = sprintf("nor/%s%03d_nor_%02d.png", anim_name, i, j);
                [cdata3 ,~ ,alpha3] = imread(filename3);
                filename4 = sprintf("nor/%s%03d_nor_%02d.png", anim_name, k, j)
                imwrite(cdata3, filename4, "Alpha", alpha3);
            end
        end
    end
end