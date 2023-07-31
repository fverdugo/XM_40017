using XM_40017
using Documenter

# Convert to html using nbconvert
function convert_notebook_to_html(notebook_path; output_name = "index", output_dir = "./docs/src/notebook-output", theme = "dark")
    command_jup = "jupyter"
    command_nbc = "nbconvert"
    output_format = "--to=html"
    theme = "--theme=$theme"
    output = "--output=$output_name"
    output_dir = "--output-dir=$output_dir"
    infile = notebook_path
    run(`$command_jup $command_nbc $output_format $output $output_dir $theme $infile`)
end

# Resize iframes using IframeResizer
function modify_notebook_html( html_name )
    content = open( html_name, "r" ) do html_file 
        read( html_file, String )
    end
    content = replace(content, 
        r"(<script\b[^>]*>[\s\S]*?<\/script>\K)" => 
        s"\1\n\t<script src='../assets/iframeResizer.contentWindow.min.js'></script>\n";
        count = 1
    )
    content = replace_colors(content)
    open( html_name, "w" ) do html_file
        write( html_file, content )
    end
    return nothing
end

# Replace colors to match Documenter.jl 
function replace_colors(content)
    content = replace( content, "--jp-layout-color0: #111111;" => "--jp-layout-color0: #1f2424;")
    content = replace(content, "--md-grey-900: #212121;" => "--md-grey-900: #282f2f;")
    return content
end

convert_notebook_to_html("docs/src/notebooks/matrix_matrix.ipynb", output_name = "matrix_matrix")
modify_notebook_html("docs/src/notebook-output/matrix_matrix.html")

convert_notebook_to_html("docs/src/notebooks/notebook-hello.ipynb", output_name = "notebook-hello")
modify_notebook_html("docs/src/notebook-output/notebook-hello.html")

makedocs(;
    modules=[XM_40017],
    authors="Francesc Verdugo <f.verdugo.rojano@vu.nl>",
    repo="https://github.com/fverdugo/XM_40017/blob/{commit}{path}#{line}",
    sitename="XM_40017",
    format=Documenter.HTML(;
        assets = ["assets/iframeResizer.min.js", "assets/custom.css"],
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://fverdugo.github.io/XM_40017",
        edit_link="main",),
    pages=["Home" => "index.md","Hello World" => "notebook-hello.md", "Notebooks"=>["Matrix Multiplication"=>"matrix_matrix.md"]],
)

deploydocs(;
    repo="github.com/fverdugo/XM_40017",
    devbranch="main",
)
