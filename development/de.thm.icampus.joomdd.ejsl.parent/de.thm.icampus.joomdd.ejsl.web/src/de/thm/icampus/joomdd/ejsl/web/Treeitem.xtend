package de.thm.icampus.joomdd.ejsl.web

import java.util.List
import java.util.LinkedList
import java.io.File
import java.util.Map
import java.util.HashMap
import org.eclipse.xtext.resource.IResourceServiceProvider
import javax.servlet.http.HttpSession

class Treeitem {
	private String id
	private String text
	private String parent
	private String icon
	private List<Treeitem> children
	private Map<String,Boolean> state
	private Map<String,String> li_attr
	private Map<String,String> a_attr
	new (String path,String parentid, String sourceName){
		children = new LinkedList<Treeitem>
		state = new HashMap<String,Boolean>
		 li_attr = new HashMap<String,String> 
	      a_attr = new  HashMap<String,String>
		searchChild(path,parentid,sourceName)
	}
	new(HttpSession session){
		var resourcesProvider = IResourceServiceProvider.Registry.INSTANCE
		children = new LinkedList<Treeitem>
		state = new HashMap<String,Boolean>
		li_attr = new HashMap<String,String> 
	     a_attr = new  HashMap<String,String>
		loadOrigin(session,resourcesProvider.contentTypeToFactoryMap.get("serverpath") as String)
		
	}
	
	def loadOrigin(HttpSession session, String source) {
		var String name = session.getAttribute("joomddusername") as String
		var File path = new File(source + "/" +name)
		this.text = path.name
		this.id = name
		icon ="jstree-folder"
			for(File item : path.listFiles){
				var Treeitem treeItem = new Treeitem(item.path, this.id,path.parentFile.name);
				children.add(treeItem);
			}
	}
	
	def searchChild(String path, String parentid, String source) {
		var File file = new File(path);
		this.text = file.name
		this.parent = file.parentFile.name
		this.id = parentid + "/" + file.name
		if(file.file){
			a_attr.put("href", source +"/"+this.id)
			var String format = file.name.split("\\.").last
			switch(format.toLowerCase){
				case "txt":{
					icon="css/txt.png"
					
				}
			case "css":{
					icon="/css/css.png"
				}
			case "php":{
				icon="/css/php.png"
			}
			case "js":{
				icon="/css/js.png"
			}
			case "sql":{
				icon="/css/sql.png"
			}
			case "html":{
				icon="/css/html.png"
			}
			case "xml":{
				icon="/css/xml.png"
			}default:{
				icon ="jstree-file"
			}
			}
		}else{
			icon ="jstree-folder"
			for(File item : file.listFiles){
				var Treeitem treeItem = new Treeitem(item.path, this.id,source);
				children.add(treeItem);
			}
		}
		
	}
	
	public def String getId(){
		return this.id
	}
	public def String getText(){
		return this.text
	}
	public def String geticon(){
		return this.icon
	}
	public def List<Treeitem>  getChildren(){
		return this.children
	}
	public def Map<String,Boolean> getState(){
		return this.state
	}
	public def void setId(String id){
		this.id= id
	}
	public def void setText(String text){
		this.text= text
	}
	public def void setIcon(String icon){
		this.icon= icon
	}
	public def void setChildren(Treeitem child){
		this.children.add(child)
		
	}
	public def void setState(String key, Boolean value){
		this.state.put(key,value);
	}
	
	override toString() {
		
		var StringBuffer result  = new StringBuffer
		
		if(children.empty){
			result.append(''' {"id":"«this.id»","text":"«this.text»","icon":"«this.icon»","parent":"«this.parent»","children":"false","state":[«this.state.toString»]}''')
		}else{
			var StringBuffer childList = new StringBuffer
		for(Treeitem item: children){
			childList.append(item.toString);
		}
			result.append(''' {"id":"«this.id»","text":"«this.text»","icon":"«this.icon»","parent":"«this.parent»","children":[«childList.toString»],"state":[«this.state.toString»]}''')
		}
		return  result.toString
	}
	
//	def static void main(String[] args) {
//		var Treeitem mm = new Treeitem("C:/joomdd_server/admin/src-gen", "admin")
//		println(mm.toString);
//	}
	
}