#!/usr/bin/python
import urllib
import os
import zipfile
import sys
import argparse
import re

# todo: change wx solution to use static crt...
# sln file:
# Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "richtext", "wx_richtext.vcxproj", "{7FB0902D-8579-5DCE-B883-DAF66A885005}"
# in vcxproj file: change:
# <RuntimeLibrary>MultiThreadedDebugDLL</RuntimeLibrary> to <RuntimeLibrary>MultiThreadedDebug</RuntimeLibrary>
# <RuntimeLibrary>MultiThreadedDLL</RuntimeLibrary> to <RuntimeLibrary>MultiThreaded</RuntimeLibrary>

# def hklm(path, var):
#     reg = registry.ConnectRegistry(None,registry.HKEY_LOCAL_MACHINE)
#     key = registry.OpenKey(reg, path)
#     value, type = registry.QueryValueEx(key, var)
#     registry.CloseKey(key)
#     registry.CloseKey(reg)
#     if not type == registry.REG_SZ:
#         raise "registry not a string!"
#     return value
#


class TextReplacer:
    def __init__(self):
        self.res = []

    def add(self, reg, rep):
        self.res.append( (reg, rep ))
        return self

    def replace(self, text):
        for r in self.res:
            reg = r[0]
            rep = r[1]
            text = text.replace(reg, rep)
        return text


root = os.getcwd()
install_dist = os.path.join(root, 'install-dist')
install = os.path.join(root, 'install')
wx_root = os.path.join(install_dist, 'wx')
build = os.path.join(root, 'build')
appveyor_msbuild = r' /logger:"C:\Program Files\AppVeyor\BuildAgent\Appveyor.MSBuildLogger.dll"'

platform = 'x64'
if os.environ.get('PLATFORM', 'unknown') == 'x86':
    platform = 'Win32'


def verify_dir_exist(path):
    if not os.path.isdir(path):
        os.makedirs(path)


def download_file(url, path):
    if not os.path.isfile(path):
        urllib.urlretrieve(url, path)
    else:
        print "Already downloaded", path


def list_projects_in_solution(path):
    ret = []
    dir = os.path.dirname(path)
    pl = re.compile(r'Project\("[^"]+"\) = "[^"]+", "([^"]+)"')
    with open(path) as sln:
        for line in sln:
            # Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "richtext", "wx_richtext.vcxproj", "{7FB0902D-8579-5DCE-B883-DAF66A885005}"
            m = pl.match(line)
            if m:
                ret.append(os.path.join(dir, m.group(1)))
    return ret


def list_projects_cmd(cmd):
    projects = list_projects_in_solution(cmd.sln)
    for p in projects:
        print "project", p


def add_definition_to_project(path, define):
    # <PreprocessorDefinitions>WIN32;_LIB;_CRT_SECURE_NO_DEPRECATE=1;_CRT_NON_CONFORMING_SWPRINTFS=1;_SCL_SECURE_NO_WARNINGS=1;__WXMSW__;NDEBUG;_UNICODE;WXBUILDING;%(PreprocessorDefinitions)</PreprocessorDefinitions>
    pp = re.compile(r'([ ]*<PreprocessorDefinitions>)([^<]*</PreprocessorDefinitions>)')
    lines = []
    with open(path) as project:
        for line in project:
            m = pp.match(line)
            if m:
                lines.append('{0}{1};{2}'.format(m.group(1), define, m.group(2)))
            else:
                lines.append(line.rstrip())
    with open(path, mode='w') as project:
        for line in lines:
            project.write(line + '\n')


def add_definition_cmd(args):
    add_definition_to_project(args.project, args.define)


# change from:
# <RuntimeLibrary>MultiThreadedDebugDLL</RuntimeLibrary> to <RuntimeLibrary>MultiThreadedDebug</RuntimeLibrary>
# <RuntimeLibrary>MultiThreadedDLL</RuntimeLibrary> to <RuntimeLibrary>MultiThreaded</RuntimeLibrary>
def change_to_static_link(path):
    mtdebug = re.compile(r'([ ]*)<RuntimeLibrary>MultiThreadedDebugDLL')
    mtrelease = re.compile(r'([ ]*)<RuntimeLibrary>MultiThreadedDLL')
    lines = []
    with open(path) as project:
        for line in project:
            mdebug = mtdebug.match(line)
            mrelease = mtrelease.match(line)
            if mdebug:
                print 'in {project} changed to static debug'.format(project=path)
                lines.append('{spaces}<RuntimeLibrary>MultiThreadedDebug</RuntimeLibrary>'.format(spaces=mdebug.group(1)))
            elif mrelease:
                print 'in {project} changed to static release'.format(project=path)
                lines.append('{spaces}<RuntimeLibrary>MultiThreaded</RuntimeLibrary>'.format(spaces=mrelease.group(1)))
            else:
                lines.append(line.rstrip())
    with open(path, mode='w') as project:
        for line in lines:
            project.write(line + '\n')


def change_to_static_cmd(args):
    change_to_static_link(args.project)


def change_all_projects_to_static(sln):
    projects = list_projects_in_solution(sln)
    for p in projects:
        change_to_static_link(p)


def change_all_projects_to_static_cmd(args):
    change_all_projects_to_static(args.sln)


def add_definition_to_solution(sln, definition):
    projects = list_projects_in_solution(sln)
    for p in projects:
        add_definition_to_project(p, definition)


def make_single_project_64(project_path, rep):
    if os.path.isfile(project_path) == False:
        print 'missing ' + project_path
        return
    lines = []
    with open(project_path) as project:
        for line in project:
            nl = rep.replace(line.rstrip())
            lines.append(nl)
    with open(project_path, 'w') as project:
        for line in lines:
            project.write(line + '\n')

def make_projects_64(sln):
    projects = list_projects_in_solution(sln)
    rep = TextReplacer()
    rep.add('Win32', 'x64')
    rep.add('<DebugInformationFormat>EditAndContinue</DebugInformationFormat>', '<DebugInformationFormat>ProgramDatabase</DebugInformationFormat>')
    rep.add('<TargetMachine>MachineX86</TargetMachine>', '<TargetMachine>MachineX64</TargetMachine>')
    # protobuf specific hack since cmake looks in x64 folder
    rep.add('<OutDir>Release\</OutDir>', '<OutDir>x64\Release\</OutDir>')
    rep.add('<OutDir>Debug\</OutDir>', '<OutDir>x64\Debug\</OutDir>')
    for project in projects:
        make_single_project_64(project, rep)


def make_solution_64(sln):
    rep = TextReplacer()
    rep.add('Win32', 'x64')

    lines = []
    with open(sln) as slnlines:
        for line in slnlines:
            nl = rep.replace(line.rstrip())
            lines.append(nl)

    with open(sln, 'w') as f:
     for line in lines:
            f.write(line + '\n')


def convert_sln_to_64(sln):
    make_solution_64(sln)
    make_projects_64(sln)


def make_solution_64_cmd(args):
    convert_sln_to_64(args.sln)


def install_cmd(args):
    global root
    global install_dist
    global wx_root
    global platform
    global appveyor_msbuild
    build = args.build

    wx_url = "https://github.com/wxWidgets/wxWidgets/releases/download/v3.1.0/wxWidgets-3.1.0.zip"
    wx_zip = os.path.join(install_dist, "wx.zip")
    wx_sln = os.path.join(wx_root, 'build', 'msw', 'wx_vc14.sln')
    wx_msbuild_cmd = 'msbuild /p:Configuration=Release /p:Platform="{platform}"{appveyor} {solution}'.format(
        appveyor=appveyor_msbuild, platform=platform, solution=wx_sln)

    print root
    print wx_sln

    verify_dir_exist(install_dist)
    verify_dir_exist(wx_root)

    print "downloading wx..."
    download_file(wx_url, os.path.join(install_dist, wx_zip))

    print "extracting wx"
    with zipfile.ZipFile(wx_zip, 'r') as z:
        z.extractall(wx_root)

    print "changing wx to static"
    change_all_projects_to_static(wx_sln)

    print "building wxwidgets"
    print "-----------------------------------"

    if build:
      sys.stdout.flush()
      os.system(wx_msbuild_cmd)


def cmake_cmd(args):
    global root
    global install_dist
    global wx_root
    global build
    global install
    global platform
    subinstall = os.path.join(install, 'windows', platform)
    os.makedirs(build)
    os.makedirs(install)
    os.makedirs(subinstall)
    generator = 'Visual Studio 14 2015'
    if os.environ.get('PLATFORM', 'unknown') == 'x64':
        generator = 'Visual Studio 14 2015 Win64'

    cmakecmd = ("cd {build} && cmake "
                "-DCMAKE_INSTALL_PREFIX={install} "
                "-DwxWidgets_ROOT_DIR={wx_root} "
                "-DRIDE_BUILD_COMMIT=%APPVEYOR_REPO_COMMIT% "
                "-DRIDE_BUILD_NUMBER=%APPVEYOR_BUILD_NUMBER% "
                "-DRIDE_BUILD_BRANCH=%APPVEYOR_REPO_BRANCH% "
                "-DRIDE_BUILD_REPO=%APPVEYOR_REPO_NAME% "
                "{generator} "
                "{root}").format(
        root=root,
        install=subinstall,
        install_dist=install_dist,
        wx_root=wx_root,
        build=build,
        generator = '-G "' + generator + '"'
    )
    sys.stdout.flush()
    os.system(cmakecmd)


def build_cmd(args):
    global build
    global platform
    global appveyor_msbuild
    ride_sln = os.path.join(build, 'PACKAGE.vcxproj')
    ride_msbuild_cmd = 'msbuild /p:Configuration=Release' \
                        ' /p:Platform="{platform}"{appveyor} {solution}'.format(
        appveyor=appveyor_msbuild, platform=platform, solution=ride_sln)
    os.system(ride_msbuild_cmd)


parser = argparse.ArgumentParser(description='Does the windows build')
subparsers = parser.add_subparsers()

install_parser = subparsers.add_parser('install')
install_parser.set_defaults(func=install_cmd)
install_parser.add_argument('--nobuild', dest='build', action='store_const', const=False, default=True)

install_parser = subparsers.add_parser('listprojects')
install_parser.set_defaults(func=list_projects_cmd)
install_parser.add_argument('sln', help='solution file')

static_project_parser = subparsers.add_parser('static_project')
static_project_parser.set_defaults(func=change_to_static_cmd)
static_project_parser.add_argument('project', help='make a project staticly link to the CRT')

static_project_parser = subparsers.add_parser('to64')
static_project_parser.set_defaults(func=make_solution_64_cmd)
static_project_parser.add_argument('sln', help='the solution to upgrade')

static_solution_parser = subparsers.add_parser('static_sln')
static_solution_parser.set_defaults(func=change_all_projects_to_static_cmd)
static_solution_parser.add_argument('sln',
                                    help='make all the projects in the specified solution staticly link to the CRT')

install_parser = subparsers.add_parser('add_define')
install_parser.set_defaults(func=add_definition_cmd)
install_parser.add_argument('project', help='project file')
install_parser.add_argument('define', help='preprocessor to add')

cmake_parser = subparsers.add_parser('cmake')
cmake_parser.set_defaults(func=cmake_cmd)

build_parser = subparsers.add_parser('build')
build_parser.set_defaults(func=build_cmd)

args = parser.parse_args()
args.func(args)
