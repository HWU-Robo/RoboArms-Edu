using CImGui
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using ImGuiGLFWBackend #CImGui.GLFWBackend
using ImGuiOpenGLBackend #CImGui.OpenGLBackend
using ImGuiGLFWBackend.LibGLFW # #CImGui.OpenGLBackend.GLFW
using ImGuiOpenGLBackend.ModernGL
using Printf

@static if Sys.isapple()
    # OpenGL 3.2 + GLSL 150
    const glsl_version = 150
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3)
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2)
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE) # 3.2+ only
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE) # required on Mac
else
    # OpenGL 3.0 + GLSL 130
    const glsl_version = 130
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3)
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0)
end

# setup GLFW error callback
#? error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"
#? GLFW.SetErrorCallback(error_callback)

# create window
window = glfwCreateWindow(1280, 720, "Robo Arm", C_NULL, C_NULL)
@assert window != C_NULL
glfwMakeContextCurrent(window)
glfwSwapInterval(1)  # enable vsync

# setup Dear ImGui context
ctx = CImGui.CreateContext()

# setup Dear ImGui style
CImGui.StyleColorsDark()

# load Fonts
# - If no fonts are loaded, dear imgui will use the default font. You can also load multiple fonts and use `CImGui.PushFont/PopFont` to select them.
# - `CImGui.AddFontFromFileTTF` will return the `Ptr{ImFont}` so you can store it if you need to select the font among multiple.
# - If the file cannot be loaded, the function will return C_NULL. Please handle those errors in your application (e.g. use an assertion, or display an error and quit).
# - The fonts will be rasterized at a given size (w/ oversampling) and stored into a texture when calling `CImGui.Build()`/`GetTexDataAsXXXX()``, which `ImGui_ImplXXXX_NewFrame` below will call.
# - Read 'fonts/README.txt' for more instructions and details.
fonts_dir = joinpath(@__DIR__, "..", "fonts")
fonts = unsafe_load(CImGui.GetIO().Fonts)
# default_font = CImGui.AddFontDefault(fonts)
CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Roboto-Medium.ttf"), 16)
# @assert default_font != C_NULL

# setup Platform/Renderer bindings
glfw_ctx = ImGuiGLFWBackend.create_context(window, install_callbacks = true)
ImGuiGLFWBackend.init(glfw_ctx)
opengl_ctx = ImGuiOpenGLBackend.create_context(glsl_version)
ImGuiOpenGLBackend.init(opengl_ctx)


#do stuff
mutable struct RJoint
    angle::Real         #theta : angle about prev z from x_old to x_new
    extension::Real     #'d' : offset along prev z to common normal
    length2Next::Real   #'r' or 'a' : length of common normal
    angle2Next::Real    #alpha : length of common normal
end

the_joint::RJoint = RJoint(0, 0, 0, 0)

joints = [
    RJoint(0, 0, 0, 0) 
    RJoint(0, 0, 4, 90)
    RJoint(0, 15, 0, 90) 
    RJoint(0, 0, 0, 0) 
    RJoint(0, 0, 0, 0)
    RJoint(0, 0, 0, 0)
]

angles::Matrix{Float32} = [0 0 0 0 0 0]
num_joints::Int16 = 5

try
    clear_color = Cfloat[0.35, 0.75, 0.50, 1.00]
    joints[1].angle = 15
    joints[num_joints].angle = 45
    println(joints[1])
    println(joints[num_joints])
    @cstatic begin
        while glfwWindowShouldClose(window) == 0
            glfwPollEvents()
            # start the Dear ImGui frame
            ImGuiOpenGLBackend.new_frame(opengl_ctx) #ImGui_ImplOpenGL3_NewFrame()
            ImGuiGLFWBackend.new_frame(glfw_ctx) #ImGui_ImplGlfw_NewFrame()
            CImGui.NewFrame()

            # show the big demo window
            # show_demo_window && @c CImGui.ShowDemoWindow(&show_demo_window)

            # show a simple window that we create ourselves.
            # we use a Begin/End pair to created a named window.
            CImGui.Begin("Joint angles")
            CImGui.Text("Each joint rotates between 0 and 180 degrees from its starting position")
            
            CImGui.Text('θ' * ' ' * 'd' * ' ' * 'r' * ' ' * 'a' * ' ')

            # for i = 1:(num_joints + 1)
            #     text = string(joints[i].angle) * ' ' * string(joints[i].extension) * ' '
            #     text = text * string(joints[i].angle2Next) * ' '
            #     text = text * string(joints[i].length2Next) * ' '
            #     CImGui.Text(text)
            # end

            # for i = 1:(num_joints + 1)
                CImGui.Columns(3, "mixed")
                CImGui.Separator()

                CImGui.Text("Hello")
                CImGui.Button("Banana")
                CImGui.NextColumn()

                CImGui.Text("ImGui")
                CImGui.Button("Apple")
                @cstatic foo=Cfloat(1.0) @c CImGui.InputFloat("red", &foo, 0.05, 0, "%.3f")
                CImGui.Text("An extra line here.")
                CImGui.NextColumn()

                CImGui.Text("Sailor")
                CImGui.Button("Corniflower")
                @cstatic bar=Cfloat(1.0) @c CImGui.InputFloat("blue", &bar, 0.05, 0, "%.3f")
                CImGui.NextColumn()

                CImGui.CollapsingHeader("Category A") && CImGui.Text("Blah blah blah")
                CImGui.NextColumn()
                CImGui.CollapsingHeader("Category B") && CImGui.Text("Blah blah blah")
                CImGui.NextColumn()
                CImGui.CollapsingHeader("Category C") && CImGui.Text("Blah blah blah")
                CImGui.NextColumn()
                CImGui.Columns(1)
                CImGui.Separator()
            # end

            for i = 1:(num_joints + 1)
                slider_name = "Joints " * string(i)
                @c CImGui.SliderFloat(slider_name, &angles[i], 0, 180)
                joints[i].angle = angles[i]
                print(string(i))
            end
            print(' ')

            CImGui.End()
            
            print("Angles: ")
            for i = 1:(num_joints-1)
                # print(angles[i + 1])
                print(joints[i + 1].angle)
                print(',')
            end
            # print(string(angles[num_joints + 1]) * '\n')
            print(string(joints[num_joints + 1].angle) * '\n')

            # rendering
            CImGui.Render()
            glfwMakeContextCurrent(window)

            width, height = Ref{Cint}(), Ref{Cint}() #! need helper fcn
            glfwGetFramebufferSize(window, width, height)
            display_w = width[]
            display_h = height[]
            
            glViewport(0, 0, display_w, display_h)
            glClearColor(clear_color...)
            glClear(GL_COLOR_BUFFER_BIT)
            ImGuiOpenGLBackend.render(opengl_ctx) #ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())

            glfwMakeContextCurrent(window)
            glfwSwapBuffers(window)
        end
    end
catch e
    @error "Error in renderloop!" exception=e
    Base.show_backtrace(stderr, catch_backtrace())
finally
    ImGuiOpenGLBackend.shutdown(opengl_ctx) #ImGui_ImplOpenGL3_Shutdown()
    ImGuiGLFWBackend.shutdown(glfw_ctx) #ImGui_ImplGlfw_Shutdown()
    CImGui.DestroyContext(ctx)
    glfwDestroyWindow(window)
end