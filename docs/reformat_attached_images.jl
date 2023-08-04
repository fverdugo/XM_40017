
function convert_embedded_img_to_base64(notebook_path)
    doc = open(io->read(io, String), notebook_path)
    # Regex matching: extract filename and base64 code
    regex = r"attachments\\\":\s*\{\s*\\\"(?<filename>.*).png\\\":\s*\{\s*\\\"image/png\\\":\s*\\\"(?<base64code>.*)\\\""
    res = eachmatch(regex, doc)
    matches = collect(res)
    # Replace img src with base64 code
    for m in matches
        global doc;
        filename = m[:filename]
        base64 = m[:base64code]
        doc = replace(doc, "attachment:$filename.png" => "data:image/png;base64,$base64")
    end

    write(notebook_path, doc);
end