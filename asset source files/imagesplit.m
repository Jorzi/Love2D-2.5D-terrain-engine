function imagesplit(alpha, cdata, n_img, outputpath)
    if ~isfolder(outputpath)
        mkdir(outputpath);
    end
    dim = size(alpha);
    img_width = dim(2)./ n_img;
    for i=1:n_img
        alpha_split = alpha(:,(i-1)*img_width+1:i*img_width);
        cdata_split = cdata(:,(i-1)*img_width+1:i*img_width,:);
        filename = sprintf('%s/%04d.png', outputpath, i)
        imwrite(cdata_split, filename, 'Alpha', alpha_split);
    end
end