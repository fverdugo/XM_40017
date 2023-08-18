using XM_40017
using Documenter
using Glob 

const md_nb_template = """
```@meta
EditURL = "https://github.com/fverdugo/XM_40017/blob/main/docs/src/notebooks/SCRIPT_NAME.ipynb"
```

```@raw html
<div class="admonition is-success">
    <header class="admonition-header">Tip</header>
    <div class="admonition-body">
        <ul>
            <li>
                Download this notebook and run it locally on your machine [recommended]. Click <a href="SCRIPT_NAME.ipynb" download>here</a>.
            </li>
            <li>
                You can also run this notebook in the cloud using Binder. Click <a href="https://mybinder.org/v2/gh/fverdugo/XM_40017/gh-pages?filepath=dev/notebooks/SCRIPT_NAME.ipynb">here</a>
                .
            </li>
        </ul>
    </div>
</div>
```

```@raw html
<iframe id="notebook" src="../notebook-html/SCRIPT_NAME.html" style="width:100%"></iframe>
<script>
  document.addEventListener('DOMContentLoaded', function(){
    var myIframe = document.getElementById("notebook");
    iFrameResize({log:true}, myIframe);	
});
</script>
```
"""

function convert_embedded_img_to_base64(notebook_path)
    doc = open(io->read(io, String), notebook_path)
    # Regex matching: extract filename and base64 code
    regex = r"attachments\\\":\s*\{\s*\\\"(?<filename>.*).png\\\":\s*\{\s*\\\"image/png\\\":\s*\\\"(?<base64code>.*)\\\""
    res = eachmatch(regex, doc)
    matches = collect(res)
    # Replace img src with base64 code
    for m in matches
        filename = m[:filename]
        base64 = m[:base64code]
        doc = replace(doc, "attachment:$filename.png" => "data:image/png;base64,$base64")
    end
    filename = splitpath(notebook_path)[end]  
    open("docs/src/notebooks/$filename","w") do f
        write(f, doc)
    end
end

# Write markdown file that includes notebook html
function create_md_nb_file( filename )
    global md_nb_template;
    content = replace(md_nb_template, "SCRIPT_NAME" => filename)
    md_path = joinpath(@__DIR__, "src/notebooks", filename * ".md" ) 
    open(md_path, "w") do md_file
        write(md_file, content)
    end
    return md_path
end

# Convert to html using nbconvert
function convert_notebook_to_html(notebook_path; output_name = "index", output_dir = "./docs/src/notebook-html", theme = "light")
    command_jup = "jupyter"
    command_nbc = "nbconvert"
    output_format = "--to=html"
    theme = "--theme=$theme"
    output = "--output=$output_name"
    output_dir = "--output-dir=$output_dir"
    infile = notebook_path
    run(`$command_jup $command_nbc $output_format $output $output_dir $theme $infile`)
end

# Modify html contents
function modify_notebook_html( html_filepath )
    content = open( html_filepath, "r" ) do html_file 
        read( html_file, String )
    end
    # Resize iframes using IframeResizer
    content = replace(content, 
        r"(<script\b[^>]*>[\s\S]*?<\/script>\K)" => 
        s"\1\n\t<script src='../assets/iframeResizer.contentWindow.min.js'></script>\n";
        count = 1
    )
    open( html_filepath, "w" ) do html_file
        write( html_file, content )
    end
    return nothing
end


# Loop over notebooks and generate html and markdown 
repo_root = joinpath(@__DIR__,"..") |> normpath
mkpath(joinpath(repo_root,"docs","src","notebooks"))
notebook_files = glob("*.ipynb", joinpath(repo_root,"notebooks/"))
for filepath in notebook_files
    convert_embedded_img_to_base64(filepath)
    filename_with_ext = splitpath(filepath)[end]    
    filename = splitext(filename_with_ext)[1]
    create_md_nb_file(filename)
    convert_notebook_to_html("docs/src/notebooks/$filename_with_ext", output_name = filename)
    modify_notebook_html("docs/src/notebook-html/$(filename).html")
end

makedocs(;
    modules=[XM_40017],
    authors="Francesc Verdugo <f.verdugo.rojano@vu.nl>",
    repo="https://github.com/fverdugo/XM_40017/blob/{commit}{path}#{line}",
    sitename="XM_40017",    
    format=Documenter.HTML(;
        assets = ["assets/favicon.ico", "assets/iframeResizer.min.js", "assets/custom.css"],
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://fverdugo.github.io/XM_40017",
        edit_link="main",),
    pages=["Home" => "index.md","Getting started"=>"getting_started_with_julia.md", "Notebooks"=>[
        "Julia Basics" => "notebooks/julia_basics.md",
        "Tasks and channels" => "notebooks/julia_async.md",
        "Remote calls and remote channels" => "notebooks/julia_distributed.md",
        "MPI" => "notebooks/mpi_tutorial.md",
        "Matrix Multiplication"=>"notebooks/matrix_matrix.md",
        "Jacobi" => "notebooks/jacobi_method.md",
        "ASP" => "notebooks/asp.md",
        "Solutions" => "notebooks/solutions.md"
    ]],
)

deploydocs(;
    repo="github.com/fverdugo/XM_40017",
    devbranch="main",
)
