## FKRealGroup - Xcode文件夹创建删除增强插件
---- 
### What is this?

---- 
FKRealGroup is a Xcode plugin to enhance create and delete groups. FKRealGroup added ”New Real Group” and 
”Delete Real Group” option to menu.

FKRealGroup是一个增强Xcode创建、删除文件夹的插件。FKRealGroup会在编辑菜单中添加”New Real Group”和”Delete Real Group”两个选项。

![image](https://raw.githubusercontent.com/Forkong/FKRealGroup/master/ScreenShots/fkrealgroup_1.jpg)

#### 新建文件夹

"New Real Group" can create a real folder on the disk, rather than the virtual folder. If the disk or project has the same name folder, it will warn.

Time if you named the folder, and did not modify the name (the default folder name is `New Group`), you pressed `ESC` or `Return`, FKRealGroup will not create real folder.(I will fix this in the future.)

我们知道，Xcode本身的”New Group”选项只会创建一个虚拟文件夹，并不会在本地磁盘创建真实文件夹。一般来说，我们会右击-\>Show in Finder-\>在文件目录创建文件夹-\>右击-\>Add Files to “xxx”…，非常繁琐。

FKRealGroup可以解决这个问题。”New Real Group”选项会在相应磁盘目录创建一个真实的文件夹，创建逻辑如下：

- 目录中无，本地有的文件夹，直接警告，不加入。
- 目录中有，本地有的文件夹，直接警告，不创建。
- 目录中无，本地无的文件夹，直接创建。
- 目录中有，本地无的文件夹，直接警告，不创建。

在”New Real Group”创建出的文件夹上，右击-\>Show in Finder，会前往正确的目录。在”New Real Group”创建出的文件夹内，新建文件或者文件夹，文件或文件夹将建于”New Real Group”创建出的文件夹内。

**如果通过”New Real Group”创建文件夹，没有修改（例如，默认新建的文件夹名称为`New Group`），直接确认(回车或者鼠标点击其他地方)，或者直接按`ESC`，将不会创建文件夹，此问题待修复。**

#### 删除文件夹

"Delete Real Group" will remove the folder to trash, if the folder is on disk.

我们在Xcode中如果使用”Delete”选项去删除文件夹，如果此文件夹为真实文件夹，那么一般情况下，Xcode只会删除此真实文件夹内的文件，而文件夹却依然存在。一般来说，我们只能”Show in Finder”,然后手动删除，这太繁琐了。

”Delete Real Group”可以解决这个问题。”Delete Real Group”会默认删除真实文件夹（如果磁盘上有此文件夹的话），不过，这里的删除并非直接删除，而是全部移动到废纸篓里面，有需要的话，可以直接捞回来。

在删除多目录、多种类的文件的时候，Xcode会进行如下的提示:

![image](https://raw.githubusercontent.com/Forkong/FKRealGroup/master/ScreenShots/fkrealgroup_2.jpg)

FKRealGroup只会在选择”Move To Trash”的情况下删除真实文件夹。
（我没有找到比较好的办法，所以这里的实现比较拙劣，如果有人知道更好的版本，请告诉我，多谢！）

### How to install it?

---- 
The best way of installing is by [Alcatraz](https://github.com/alcatraz/Alcatraz). 

推荐使用[Alcatraz](https://github.com/alcatraz/Alcatraz)。

你也可以clone整个工程，然后编译，插件会自动安装到`~/Library/Application Support/Developer/Shared/Xcode/Plug-ins`这个目录上。

一定要选Load Bundle，Skip的话，插件是无法生效的。

### How to use it?

---- 
点击Xcode的Plugins菜单，在FKRealGroup选项上可以进行开关。

![image](https://raw.githubusercontent.com/Forkong/FKRealGroup/master/ScreenShots/fkrealgroup_3.jpg)

### Xcode version?

---- 
- Xcode 7

### License

---- 
MIT.
