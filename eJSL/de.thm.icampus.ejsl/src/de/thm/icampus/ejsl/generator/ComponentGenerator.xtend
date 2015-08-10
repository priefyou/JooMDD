	/**
 */
package de.thm.icampus.ejsl.generator;

import de.thm.icampus.ejsl.eJSL.BackendSection
import de.thm.icampus.ejsl.eJSL.Component
import de.thm.icampus.ejsl.eJSL.DetailsPage
import de.thm.icampus.ejsl.eJSL.Entity
import de.thm.icampus.ejsl.eJSL.FrontendSection
import de.thm.icampus.ejsl.eJSL.IndexPage
import de.thm.icampus.ejsl.eJSL.Language
import de.thm.icampus.ejsl.eJSL.Page
import de.thm.icampus.ejsl.eJSL.Parameter
import de.thm.icampus.ejsl.eJSL.Section
import java.util.ArrayList
import java.util.Calendar
import java.util.HashSet
import org.eclipse.emf.common.util.EList
import org.eclipse.xtext.generator.IFileSystemAccess
import java.util.HashMap
import de.thm.icampus.ejsl.eJSL.ParameterGroup
import de.thm.icampus.ejsl.eJSL.Attribute
import de.thm.icampus.ejsl.eJSL.Reference
import de.thm.icampus.ejsl.eJSL.DynamicPage
import de.thm.icampus.ejsl.eJSL.StaticPage

public class ComponentGenerator extends AbstractExtensionGenerator {

	private String slug
	private Component component
    private String class_name
    
	new(Component component, IFileSystemAccess fsa) {
		this.fsa = fsa;
		this.slug = Slug.slugify(component.name)
		this.noPrefixName = this.slug
		this.name = "com_" + this.slug

		this.component = component
		this.class_name = this.noPrefixName.toFirstUpper
	}

	override generate() {
		generateJoomlaDirectory("")
		
		/*
		 *  indexPage variable will be used for manifest <submenu> tag
		 *  In XTEND there are some bugs with instanceof command
		 *  For this reason all index pages of section will be
		 *  find and saved here
		 */
		var indexPages = new ArrayList();
		for(Section s :component.sections) {
			switch (s){
				BackendSection : {
				for(Page p : s.page) {
					if(p instanceof IndexPage) {
						indexPages.add(p);			
					}
				}
			}
			}
		}
		
		generateFile(name + ".xml", component.xmlContent(indexPages))

		var frontend = null as FrontendSection
		var backend = null as BackendSection

		if (component.sections.length > 0) {
			switch component.sections.get(0) {
				BackendSection: backend = component.sections.get(0) as BackendSection
				FrontendSection: frontend = component.sections.get(0) as FrontendSection
			}
		}

		if (component.sections.length > 1) {
			switch component.sections.get(1) {
				BackendSection: backend = component.sections.get(1) as BackendSection
				FrontendSection: frontend = component.sections.get(1) as FrontendSection
			}
		}

		// Generate language files
		for (lang : component.languages) {
			val ldir = lang.name
			generateFile("language/" + ldir + "/" + ldir + "." + name + ".ini", lang.languageFileContent)
			generateFile("language/" + ldir + "/" + ldir + "." + name + ".sys.ini", lang.languageFileContent)
		}

		// Generate backend section 
		if (backend != null) {
			backend.generateBackendSection
		}

		// Generate frontend section 
		if (frontend != null) {
			frontend.generateFrontendSection
		}

		// Generate sql stuff
		generateJoomlaDirectory("admin/sql")
		generateFile("admin/sql/install.mysql.utf8.sql", component.sqlAdminSqlInstallContent(false))
		generateFile("admin/sql/uninstall.mysql.utf8.sql", component.sqlAdminSqlUninstallContent)
		generateJoomlaDirectory("admin/sql/updates")
		generateJoomlaDirectory("admin/sql/updates/mysql")
		generateFile("admin/sql/updates/mysql/1.0.1.mysql.utf8.sql", component.sqlAdminSqlUpdateContent(true))
		
		return ""
	}
	
	// Alle untergeordneten (über Referenzen) Entities finden
	def Iterable<Entity> getEntities(Component component) {
		var entities = new HashSet<Entity>();
		
		// Section -> Page -> Entities
		for(Section s :component.sections) {
			for(Page p : s.page) {
				if(p instanceof IndexPage) {
					entities.addAll((p as IndexPage).entities)
				} else if(p instanceof DetailsPage) {
					entities.addAll((p as DetailsPage).entities)
				}
			}
		}

		return entities;
	}
	
	 def CharSequence sqlAdminSqlInstallContent(Component component, boolean isupdate) {
        val Iterable<Entity> entities=getEntities(component)
        var HashSet<Entity> visited = new HashSet<Entity>();
        var StringBuffer result = new StringBuffer;
        while(visited.size != entities.size){
	        for (Entity e:entities){
	        	if(e.references.empty && !visited.contains(e)){
	        		result.append(generateSQLTable(e, isupdate));
	        		visited.addAll(e);
	        	}
	        	if(!visited.contains(e) && !e.references.empty && isAllreferenVisited(e.references, visited) ){
	        
	        	   result.append(generateSQLTable(e, isupdate))
	        	   visited.addAll(e);
	        	}
	        }
	       }
         return result.toString
     
   }
	
	def boolean isAllreferenVisited(EList<Reference> list, HashSet<Entity> entities) {
		
		for(Reference r: list){
			if(!entities.contains(r.entity))
			return false
		}
		return true
	}
    
    def CharSequence generateSQLTable(Entity table, boolean isupdate)'''
    «IF !isupdate»
    DROP TABLE IF EXISTS `#__«table.name.toLowerCase»`;
    «ENDIF»

   CREATE TABLE «IF isupdate» IF NOT EXISTS «ENDIF»`#__«table.name.toLowerCase»` (
    `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,    
    `ordering` INT(11)  NOT NULL ,
    `state` TINYINT(1)  NOT NULL ,
    `checked_out` INT(11)  NOT NULL,
    `checked_out_time` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
	`created_by` INT(11)  NOT NULL ,
	«FOR a:table.attributes»
		`«a.name.toLowerCase»` «Slug.getTypeName(a.dbtype)»,
	«ENDFOR»
«FOR r:table.references»
	FOREIGN KEY (`«r.attribute.name.toLowerCase»`) REFERENCES `#__«r.entity.name.toLowerCase»` (`«r.attributerefereced.name.toLowerCase»`)
	ON UPDATE CASCADE
	ON DELETE CASCADE,
«ENDFOR»
PRIMARY KEY (`id`)
«FOR a:table.attributes»
«IF a.isprimary»
,  UNIQUE KEY («a.name»)
«ENDIF»
«ENDFOR»
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
'''
	
	def Attribute getPrimaryKeyOfTable(Entity entity) {
		
		for(Attribute e : entity.attributes){
			if(e.isprimary)
			return e
		}
	}
    
   def CharSequence sqlAdminSqlUninstallContent(Component component) '''
        «/*val entities=component.eAllContents.toIterable.filter(typeof(Entity))*/»
        «val entities=getEntities(component)»
        «FOR e:entities»
        	DROP TABLE IF EXISTS `#__«e.name.toLowerCase»`;
        «ENDFOR»
    '''
    
	def CharSequence sqlAdminSqlUpdateContent(Component component, boolean isupdate) {
		return sqlAdminSqlInstallContent(component, isupdate);
    }
    
	def CharSequence languageFileContent(Language lang) '''
	«Slug.nameExtensionBind("com", component.name).toUpperCase» = «component.name.toFirstUpper»
	«Slug.nameExtensionBind("com", component.name).toUpperCase»_HOME = Home
	«Slug.nameExtensionBind("com", component.name).toUpperCase»_FORM_LBL_NONE_ID = ID
	«Slug.nameExtensionBind("com", component.name).toUpperCase»_FORM_LBL_NONE_CHECKED_OUT = Checked out
	«Slug.nameExtensionBind("com", component.name).toUpperCase»_FORM_LBL_NONE_CHECKED_OUT_TIME = Checked out Time
	«Slug.nameExtensionBind("com", component.name).toUpperCase»_FORM_LBL_NONE_ORDERING = Ordering
	«Slug.nameExtensionBind("com", component.name).toUpperCase»_FORM_LBL_NONE_CREATED_BY = Created By
	«Slug.nameExtensionBind("com", component.name).toUpperCase»_FORM_LBL_NONE_STATE= state
	«FOR Section sec: component.sections»
	«FOR Page pag: sec.page»
	«Slug.nameExtensionBind("com", component.name).toUpperCase»_TITLE_«pag.name.toUpperCase» = «pag.name.toFirstUpper»
	«ENDFOR»
	«ENDFOR»
	«FOR DetailsPage dynp: Slug.getAllAttributeOfAComponente(component)»
	    «FOR Attribute attr: dynp.entities.last.attributes»
		«Slug.nameExtensionBind("com", component.name).toUpperCase»_FORM_LBL_«dynp.name.toUpperCase»_«attr.name.toUpperCase» = «attr.name.toFirstUpper»
		«ENDFOR»
	«ENDFOR»
	«FOR e : lang.keyvaluepairs»
		«Slug.generateKeysName(component,e.name)»="«e.value»"
	«ENDFOR»
	'''

	def CharSequence xmlContent(Component component, ArrayList<Page> indexPages) '''
		<?xml version="1.0" encoding="utf-8"?>
		<extension type="component" version="3.3" method="upgrade">
		    <name>«component.name»</name>
		    «component.manifest.authors.generate»            
		    «IF (component.manifest.creationdate != null)»
		    	<creationDate>«component.manifest.creationdate»</creationDate>
		    «ELSE»
		    	<creationDate>«Calendar::instance.get(Calendar::YEAR)»</creationDate>
		    «ENDIF»
		    «IF (component.manifest.copyright != null)»
		    	<copyright>«component.manifest.copyright»</copyright>
		    «ENDIF»
		    «IF (component.manifest.license != null)»
		    	<license>GPL 2.0</license>
		    «ENDIF»
		    «IF (component.manifest.version != null)»
		    	<version>«component.manifest.version»</version>
		    «ENDIF»
		    «IF (component.manifest.description != null)»
		    	<description>«component.manifest.description»</description>
		    «ENDIF»
		     <version>1.0.1</version>
		    <!-- Install Section -->
		    <install>
		        <sql>
		            <file driver="mysql" charset="utf8">sql/install.mysql.utf8.sql</file>
		        </sql>
		    </install>
		    
		    <!-- Uninstall Section -->
		    <uninstall>
		        <sql>
		            <file driver="mysql" charset="utf8">sql/uninstall.mysql.utf8.sql</file>
		        </sql> 
		    </uninstall>
		    
		    <!-- Update Section -->
		    <update>
		        <schemas>
		            <schemapath type="mysql">sql/updates/mysql</schemapath>
		        </schemas>
		    </update>
		    
		    <!-- Site Main File Copy Section -->
		    <files folder="site">
		        <filename>index.html</filename>
		        <filename>«noPrefixName».php</filename>
		        <filename>controller.php</filename>
		        <!-- Additional Files -->
		        <folder>views</folder>
		        <folder>models</folder>
		        <folder>controllers</folder>		       
		    </files>
		    
		    <languages folder="site">
		    	«FOR lang : component.languages»
		    		<language tag="«lang.name»">language/«lang.name»/«lang.name».«this.name».ini</language>
		    	«ENDFOR»
		    </languages>
		    
		    <administration>
		        <!-- Administration Menu Section -->
		        <menu>«Slug.nameExtensionBind("com",component.name).toUpperCase»</menu>
		        <submenu>
				«FOR page : indexPages»
					
					<menu link="option=«Slug.nameExtensionBind("com",component.name).toLowerCase»&amp;view=«page.name.toLowerCase»" 
					alias="«page.name.toFirstUpper»"
					view="«page.name.toLowerCase»">«Slug.nameExtensionBind("com", component.name).toUpperCase»_TITLE_«page.name.toUpperCase»</menu>
				«ENDFOR»
		        </submenu>
		        <!-- Administration Main File Copy Section -->
		        <files folder="admin">
		            <!-- Admin Main File Copy Section -->
		            <filename>index.html</filename>
		            <filename>«noPrefixName».php</filename>
		            <filename>controller.php</filename>
					<filename>access.xml</filename>
					<filename>config.xml</filename>
		            <!-- SQL Files Section -->
		            <folder>sql</folder>
		            <!-- Table Files Section -->
		            <folder>tables</folder>
		            <!-- Model Files Section -->
		            <folder>models</folder>
		            <!-- View Files Section -->
		            <folder>views</folder>
		            <folder>controllers</folder>
		            <folder>helpers</folder>
		            <folder>assets</folder>
		        </files>
				
				<languages folder="administrator">
		    	«FOR lang : component.languages»
		    		<language tag="«lang.name»">language/«lang.name»/«lang.name».«this.name».ini</language>
		    	«ENDFOR»
				</languages>
		    </administration>
		</extension>
	'''

	private def void generateFrontendSection(Section section) {

		//Generate frontend section
		generateJoomlaDirectory("/site")
		generateFile("site/" + noPrefixName + ".php", component.phpSiteContent)
		generateFile("site/controller.php", component.phpSiteControllerContent)
		generateFile("site/router.php", component.phpSiteRouterContent)
		generateJoomlaDirectory("site/views")
		var tempSlug = slug + "s"
//		generateJoomlaDirectory("site/views/" + tempSlug)
//		generateFile("site/views/" + tempSlug + "/view.html.php", component.phpSiteViewContent)
//		generateFile("site/views/" + tempSlug + "/tmpl/default.xml", component.xmlSiteTemplateContent)
//		generateFile("site/views/" + tempSlug + "/tmpl/default.php", component.phpSiteTemplateContent)

		generateJoomlaDirectory("site/models")

		generateJoomlaDirectory("site/views")

		generateJoomlaDirectory("site/controllers")

		val pagerefs = section.page
		for (pageref : pagerefs) {
			println(pageref.name)
			pageref.generate("com_"+component.name.toLowerCase + "/site","site")
		}
	}
	
	

	private def void generateBackendSection(Section section) {
		generateJoomlaDirectory("admin")
		generateFile("admin/" + noPrefixName + ".php", component.phpAdminContent)
		generateFile("admin/controller.php", component.phpAdminControllerContent)
		
		generateFile("admin/access.xml", component.xmlAccessContent)
		generateFile("admin/config.xml", component.xmlConfigContent)
		
		generateJoomlaDirectory("admin/views")
		println(slug)
		var tempSlug = slug + "s"
		generateJoomlaDirectory("admin/views/" + tempSlug)
		generateFile("admin/views/" + tempSlug + "/view.html.php", component.phpAdminViewContent)
		generateJoomlaDirectory("admin/views/" + tempSlug + "/tmpl")
		generateFile("admin/views/" + tempSlug + "/tmpl/default.php", component.phpAdminTemplateContent)

		generateJoomlaDirectory("admin/models")
		generateJoomlaDirectory("admin/models/fields")
		generateJoomlaDirectory("admin/tables")
		generateTable("admin/tables/")

		generateJoomlaDirectory("admin/views")

		generateJoomlaDirectory("admin/controllers")
		generateJoomlaDirectory("admin/helpers/")
		generateFile("admin/helpers/" + component.name.toLowerCase + ".php", generateHelperComponent)
		
		generateJoomlaDirectory("admin/assets")
		

		// commented out old model generation code
		
		val pagerefs = section.page
		for (pageref : pagerefs) {
			pageref.generate("com_"+component.name.toLowerCase + "/admin","admin")

		}
	}
	
	def generateTable(String path) {
		for(Section sect: component.sections){
			for(Page pg: sect.page){
				switch pg{
					DetailsPage :{
						generateFile(path + pg.name.toLowerCase + ".php", phpAdminTableContent(pg))
					}
				}
			}
		}
	}

    def generate(Page pageref, String path, String section) {
        if (pageref instanceof DynamicPage) {
            val name = Slug.slugify(pageref.name)        
            
            var String viewPath = path + "/views";
            PageGeneratorClient.generateView(pageref, component, section, viewPath, fsa)
            var String controllerpath = path + "/controllers"
            PageGeneratorClient.generateController(pageref, component, section, controllerpath,fsa)
            var String modelpath = path + "/models"
            PageGeneratorClient.generateModel(pageref, component, section, modelpath,fsa)
        } else if (pageref instanceof StaticPage) {
            PageGeneratorClient.generateStaticPage(pageref)
        }
    }
    
	def CharSequence phpSiteContent(Component component) '''
        <?php
             «Slug.generateFileDoc(component,true)»
            
            // Get parameters
            // $.. = $params->get(..);
            
            // import joomla controller library
            jimport('joomla.application.component.controller');
            
            // Get an instance of the controller prefixed by «class_name»
            $controller = JControllerLegacy::getInstance('«class_name»');
            
            // Perform the Request task
            $input = JFactory::getApplication()->input;
            $controller->execute($input->getCmd('task'));
            
            // Redirect if set by the controller
            $controller->redirect();
    '''
    
    def CharSequence phpSiteControllerContent(Component component) '''
        <?php
             «Slug.generateFileDoc(component,true)»
            
            // import Joomla controller library
            jimport('joomla.application.component.controller');
            
            /**
             * General Controller of «component.name» component
             */
            class «class_name»Controller extends JControllerLegacy
            {
                    /**
                     * display task
                     *
                     * @return void
                     */
                    function display($cachable = false) 
                    {
                            // set default view if not set
                            $input = JFactory::getApplication()->input;
                            $input->set('view', $input->getCmd('view', '«component.name»'));
            
                            // call parent behavior
                            parent::display($cachable);
                    }
            }
    '''
    
    def CharSequence phpSiteViewContent(Component component) '''
        <?php
             «Slug.generateFileDoc(component,true)»
            
            // import Joomla view library
            jimport('joomla.application.component.view');
            
            /**
             * HTML View class for the «class_name» Component
             */
            class «class_name»View«class_name» extends JView
            {
                // Overwriting JView display method
                function display($tpl = null) 
                {
                    // Assign data to the view
                    $this->msg = $this->get('Msg');
                    
                    // Check for errors.
                    if (count($errors = $this->get('Errors'))) 
                    {
                        JLog::add(implode('<br />', $errors), JLog::WARNING, 'jerror');
                        return false;
                    }
                    // Display the view
                    parent::display($tpl);
                }
            }
    '''
    
    def CharSequence xmlSiteTemplateContent(Component component) '''
        <?xml version="1.0" encoding="utf-8"?>
        <metadata>
            <layout title="«name.toUpperCase»_VIEW_DEFAULT_TITLE">
                <message><![CDATA[«name.toUpperCase»_VIEW_DEFAULT_DESC]]></message>
            </layout>
            <fields
                name="request"
                addfieldpath="administrator/components/«name»/models/fields"
            >
                <fieldset name="request">
                    <field
                        name="id"
                        type="«name»"
                        label="«name.toUpperCase»_FIELD_GREETING_LABEL"
                        description="«name.toUpperCase»_FIELD_GREETING_DESC"
                    />
                </fieldset>
            </fields>
        </metadata>
    '''
    
    def CharSequence phpSiteTemplateContent(Component component) '''
        <?php
            // No direct access to this file
            defined('_JEXEC') or die('Restricted access');
        ?>
        <h1><?php echo $this->msg; ?></h1>
    '''
    
     /**
     * generate simple frontendModel file contents,
     * which extend from JModelItem in general and access single items (not lists)
     */
    def CharSequence phpSiteModelContent(Component component, Page pageref) '''
        <?php
            «Slug.generateFileDoc(component,true)»
             
            // import Joomla modelitem library
            jimport('joomla.application.component.modelitem');
             
            /**
             * «class_name» Model
             */
            class «component.name.toFirstUpper»Model«pageref.name.toFirstUpper» extends JModelItem
            {
                    /**
                     * @var array messages
                     */
                    protected $messages;
             
                    /**
                     * Returns a reference to the a Table object, always creating it.
                     *
                     * @param       type    The table type to instantiate
                     * @param       string  A prefix for the table class name. Optional.
                     * @param       array   Configuration array for model. Optional.
                     * @return      JTable  A database object
                     * @since       2.5
                     */
                    public function getTable($type = '«class_name»', $prefix = '«class_name»Table', $config = array()) 
                    {
                            return JTable::getInstance($type, $prefix, $config);
                    }
                    /**
                     * Get the message
                     * @param  int    The corresponding id of the message to be retrieved
                     * @return string The message to be displayed to the user
                     */
                    public function getMsg($id = 1) 
                    {
                            if (!is_array($this->messages))
                            {
                                    $this->messages = array();
                            }
             
                            if (!isset($this->messages[$id])) 
                            {
                                    //request the selected id
                                    $jinput = JFactory::getApplication()->input;
                                    $id = $jinput->get('id', 1, 'INT' );
             
                                    // Get a Table«class_name» instance
                                    $table = $this->getTable();
             
                                    // Load the message
                                    $table->load($id);
             
                                    // Assign the message
                                    $this->messages[$id] = $table->greeting;
                            }
             
                            return $this->messages[$id];
                    }
            }
    '''
    
    def CharSequence phpAdminContent(Component component) '''
		<?php
		 «Slug.generateFileDoc(component,true)»
		
		// Access check.
		if (!JFactory::getUser()->authorise('core.manage', '«Slug::nameExtensionBind("com",component.name )»')) 
		{
			throw new Exception(JText::_('JERROR_ALERTNOAUTHOR'));
		}
		
		// Include dependancies
		jimport('joomla.application.component.controller');
		
		// Get an instance of the controller prefixed by «Slug::nameExtensionBind("com",component.name )»
		$controller	= JControllerLegacy::getInstance('«component.name.toFirstUpper»');
		$controller->execute(JFactory::getApplication()->input->get('task'));
		$controller->redirect();
    '''
    
    def CharSequence phpAdminControllerContent(Component component) '''
        <?php
             «Slug.generateFileDoc(component,true)»
            
            // import Joomla controller library
            jimport('joomla.application.component.controller');
            
            /**
             * General Controller of «class_name» component
             */
            class «class_name»Controller extends JControllerLegacy
            {
                    /**
                     * display task
                     *
                     * @return void
                     */
                     public function display($cachable = false, $urlparams = false) 
                     {
                     	
                        require_once JPATH_COMPONENT . '/helpers/«component.name.toLowerCase».php';
                        $view = JFactory::getApplication()->input->getCmd('view', '«class_name»s');
                        JFactory::getApplication()->input->set('view', $view);
                        parent::display($cachable, $urlparams);
                        return $this;
                      }
            }
    '''
    
    /**
     * returns the content of a simple backendSection model file
     * that extends from JModelAdmin and provides methods 
     * to handle (load,edit...) one data item
     */
    def CharSequence phpAdminSimpleModelContent(Component component, Page pageref)'''
		<?php
		
		 «Slug.generateFileDoc(component,true)»

		jimport('joomla.application.component.modeladmin');

		class «component.name.toFirstUpper»Model«pageref.name.toFirstUpper» extends JModelAdmin
		{
		}
    '''
    
    def CharSequence phpAdminTemplateContent(Component component) '''
<?php
 «Slug.generateFileDoc(component,true)»
?>
<div >
	</div>
	<p class="text-center"> <h1><?php echo JText::_('«Slug.nameExtensionBind("com", component.name).toUpperCase»') . " ". JText::_('«Slug.nameExtensionBind("com", component.name).toUpperCase»_HOME'); ?> </h1> </p> 
	<div id="cpanel" class='cpanel'>
	<?php foreach ($this->views as $view)
	{
	?>
	    <div class="icon">
	        <h3><a href='<?php echo $view['url']; ?>'
	            <span><?php echo $view['title']; ?></span>
	        </a></h3>
	        <br />
	    </div>
	<?php
	}
	?>
</div>  
			
    '''
    
    def CharSequence phpAdminTemplateHeadContent(Component component) '''
        <?php
             «Slug.generateFileDoc(component,true)»
            ?>
            <tr>
                    <th width="5">
                            <?php echo JText::_('COM_«name.toUpperCase»_«name.toUpperCase»_HEADING_ID'); ?>
                    </th>
                    <th width="20">
                            <input type="checkbox" name="toggle" value="" onclick="checkAll(<?php echo count($this->items); ?>);" />
                    </th>                   
                    <th>
                            <?php echo JText::_('COM_«name.toUpperCase»_«name.toUpperCase»_HEADING_GREETING'); ?>
                    </th>
            </tr>
    '''
    
    def CharSequence phpAdminTemplateBodyContent(Component component) '''
        <?php
            «Slug.generateFileDoc(component,true)»
        ?>
        <?php foreach($this->items as $i => $item): ?>
            <tr class="row<?php echo $i % 2; ?>">
                <td>
                    <?php echo $item->id; ?>
                </td>
                <td>
                    <?php echo JHtml::_('grid.id', $i, $item->id); ?>
                </td>
                <td>
                    <?php echo $item->greeting; ?>
                </td>
            </tr>
        <?php endforeach; ?>    
    '''
    
        
    def CharSequence phpAdminTemplateFootContent(Component component) '''
        <?php
            // No direct access to this file
            defined('_JEXEC') or die('Restricted Access');
        ?>
        <tr>
            <td colspan="3"><?php echo $this->pagination->getListFooter(); ?></td>
        </tr>
    '''
    
        
    def CharSequence phpAdminTableContent(DynamicPage page) '''
        <?php
            «Slug.generateFileDoc(component,true)»
             
            // import Joomla table library
            jimport('joomla.database.table');
             
            /**
             * «page.name.toFirstUpper» Table class
             */
            class «component.name.toFirstUpper»Table«page.name.toFirstUpper» extends JTable
            {
                /**
                 * Constructor
                 *
                 * @param object Database connector object
                 */
                function __construct(&$db) 
                {
                        parent::__construct('#__«page.entities.get(0).name.toLowerCase»', 'id', $db);
                }
            }
    '''
    
    def CharSequence phpAdminViewContent(Component component) '''
<?php
«Slug.generateFileDoc(component,true)»
// import Joomla view library
jimport('joomla.application.component.view');
 
/**
 * «class_name» View
 */
class «class_name»View«class_name»s extends JViewLegacy
{

 /** Method to get display
 *
 * @param   Object  $tpl  template
 *
 * @return void
 * @generated
 */
    public function display($tpl = null)
    {
        if (!JFactory::getUser()->authorise('core.administrator'))
        {
            return JError::raiseWarning(404, JText::_('JERROR_ALERTNOAUTHOR'));
        }

        JHtml::_('behavior.tooltip');

        $document = JFactory::getDocument();

        JHtml::_('tabs.start');

        $application = JFactory::getApplication("administrator");
        $this->option = $application->scope;

        $this->addToolBar();

        $this->addViews();

        parent::display($tpl);
    }

/**
 * creates a joomla administratoristrative tool bar
 *
 * @return void
 * @generated
 */
    private function addToolBar()
    {
        JToolBarHelper::title(JText::_('«Slug.nameExtensionBind("com", component.name).toUpperCase»') . ': ' . JText::_('«Slug.nameExtensionBind("com", component.name).toUpperCase»_HOME'), 'logo');
        JToolBarHelper::preferences('«Slug.nameExtensionBind("com", component.name).toLowerCase»');
    }

/**
 * creates html elements for the main menu
 *
 * @return void
 * @generated
 */
    private function addViews()
    {
        $views = array();
«FOR Page pg: Slug::getBackendSectionViews(component).page»

     «switch (pg) {
     	
     	IndexPage :{
     		'''
		$views['«pg.name.toLowerCase»'] = array();
		$views['«pg.name.toLowerCase»']['title'] = JText::_('«Slug.nameExtensionBind("com", component.name).toUpperCase»_TITLE_«pg.name.toUpperCase»');
		$views['«pg.name.toLowerCase»']['url'] = "index.php?option=«Slug.nameExtensionBind("com", component.name).toLowerCase»&view=«pg.name.toLowerCase»";
     		'''
     	}
     }»
«ENDFOR»
      
$this->views = $views;
}
}
    '''
    
    def CharSequence xmlAccessContent(Component component) '''
		<?xml version="1.0" encoding="utf-8"?>
		<access component="«name»">
		<section name="component">
			<action name="core.admin" title="JACTION_ADMIN" description="JACTION_ADMIN_COMPONENT_DESC" />
			<action name="core.manage" title="JACTION_MANAGE" description="JACTION_MANAGE_COMPONENT_DESC" />
			<action name="core.create" title="JACTION_CREATE" description="JACTION_CREATE_COMPONENT_DESC" />
			<action name="core.delete" title="JACTION_DELETE" description="JACTION_DELETE_COMPONENT_DESC" />
			<action name="core.edit" title="JACTION_EDIT" description="JACTION_EDIT_COMPONENT_DESC" />
			<action name="core.edit.state" title="JACTION_EDITSTATE" description="JACTION_EDITSTATE_COMPONENT_DESC" />
			<action name="core.edit.own" title="JACTION_EDITOWN" description="JACTION_EDITOWN_COMPONENT_DESC" />
		</section>
		«xmlAccessContentPage(component.sections)»
		</access>
    '''
	
	def xmlAccessContentPage(EList<Section> list) '''
	«FOR Section s: list»
	 «FOR Page dyn: s.page»
	 <section name="«dyn.name.toLowerCase»">
	 <action name="core.create" title="JACTION_CREATE" description="JACTION_CREATE_COMPONENT_DESC" />
	 <action name="core.delete" title="JACTION_DELETE" description="JACTION_DELETE_COMPONENT_DESC" />
	 <action name="core.edit" title="JACTION_EDIT" description="JACTION_EDIT_COMPONENT_DESC" />
	 <action name="core.edit.state" title="JACTION_EDITSTATE" description="JACTION_EDITSTATE_COMPONENT_DESC" />
	 <action name="core.edit.own" title="JACTION_EDITOWN" description="JACTION_EDITOWN_COMPONENT_DESC" />
	 </section>
	 «ENDFOR»
	«ENDFOR»
	'''
	
    // Alle untergeordneten (über Referenzen) Entities finden
	def Iterable<ParameterGroup> getGlobalparameters(Component component) {
		var params=new HashSet<ParameterGroup>();
		
		// Section -> Page -> GlobalParameter
		for(Section s :component.sections) {
			for(Page p : s.page) {
				for(ParameterGroup para : p.parametergroups) {
					if(!params.contains(para))
					params.add(para);
				}
			}
		}

		return params;
	}
    
    def CharSequence xmlConfigContent(Component component) '''
     	«val params=getGlobalparameters(component)»
		<?xml version="1.0" encoding="utf-8"?>
		<config>
			<fieldset name="component" label="«name.toUpperCase»_LABEL" description="«name.toUpperCase»_DESC">
			«FOR g:component.globalParamter»
			«FOR p:g.parameters»
			«writeParameter(p)»
			«ENDFOR»
			«ENDFOR»
			</fieldset>
			«FOR page_param:params»
			<fieldset name="«page_param.name»" label="«page_param.name.toUpperCase»_LABEL" description="«page_param.name.toUpperCase»_DESC">
			«FOR page_param_item:page_param.globalparameters»
			«writeParameter(page_param_item)»
			«ENDFOR»
			</fieldset>
			«ENDFOR»
			
		</config>
    '''
    def CharSequence writeParameter(Parameter param)'''
    <field
    name="«param.name»"
    type="«Slug.getTypeName(param.dtype)»"
    default="«param.defaultvalue»"
    label="«param.label»"
    description="«param.descripton»"
    >
    '''
    def CharSequence generateHelperComponent() '''
    <?php
     «Slug.generateFileDoc(component,true)»

/**
 * «component.name.toUpperCase»  helper.
 */
class «component.name.toFirstUpper»Helper {

    /**
     * Configure the Linkbar.
     */
    public static function addSubmenu($vName = '') {
    	«FOR Page pg: Slug::getBackendSectionViews(component).page»
    	
    	     «switch (pg) {
    	     	
    	     	IndexPage :{
    	     		'''
        		JHtmlSidebar::addEntry(
        		
        		JText::_('«pg.name.toUpperCase»'),
        		'index.php?option=«Slug.nameExtensionBind("com",component.name).toLowerCase»&view=«pg.name.toLowerCase»',
        		$vName == '«pg.name.toLowerCase»'
        		);
    	     		'''
    	     	}
    	     }»
        «ENDFOR»

        		}

    /**
     * Gets a list of the actions that can be performed.
     *
     * @return	JObject
     * @since	1.6
     */
    public static function getActions() {
        $user = JFactory::getUser();
        $result = new JObject;

        $assetName = '«Slug::nameExtensionBind('com', component.name)»';

        $actions = array(
            'core.admin', 'core.manage', 'core.create', 'core.edit', 'core.edit.own', 'core.edit.state', 'core.delete'
        );

        foreach ($actions as $action) {
            $result->set($action, $user->authorise($action, $assetName));
        }

        return $result;
    }


}
    '''
    def CharSequence phpSiteRouterContent(Component component)'''
 <?php
   «Slug.generateFileDoc(component,true)»
  /**
 * @param	array	A named array
 * @return	array
 */
function «component.name.toFirstUpper»BuildRoute(&$query) {
    $segments = array();

    if (isset($query['task'])) {
        $segments[] = implode('/', explode('.', $query['task']));
        unset($query['task']);
    }
    if (isset($query['view'])) {
        $segments[] = $query['view'];
        unset($query['view']);
    }
    if (isset($query['id'])) {
        $segments[] = $query['id'];
        unset($query['id']);
    }

    return $segments;
}

/**
 * @param	array	A named array
 * @param	array
 *
 *
 */
function «component.name.toFirstUpper»ParseRoute($segments) {
    $vars = array();

    // view is always the first element of the array
    $vars['view'] = array_shift($segments);

    while (!empty($segments)) {
        $segment = array_pop($segments);
        if (is_numeric($segment)) {
            $vars['id'] = $segment;
        } else {
            $vars['task'] = $vars['view'] . '.' . $segment;
        }
    }

    return $vars;
}
    
    
	'''
    		
	override getProtectedRegions() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override setProtectedRegions(EList<ProtectedRegion> myprotectedRegions) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override getSlug() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override setSlug(Slug slug) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override getKvPairClient() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override setKvPairClient(KVPairGeneratorClient e) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

} // ComponentGenerator
