#ifndef CORE_H
#define CORE_H

//OGRE 
#include <Ogre.h>
#include <OgreLog.h>
#include <OgreTerrain.h>
#include <OgreTerrainPaging.h>

//CCS
#include <CCSCameraControlSystem.h>

//MyGUI
#include <MyGUI.h>
#include <MyGUI_OgrePlatform.h>

//Input System
#include <OIS/OIS.h>

//Physics subsystem
#include <btBulletDynamicsCommon.h>
#include "BtOgrePG.h"
 
//Object Types
#include "ObjectFactory.h"

//Event dispatching support
#include "OgreEventListener.h"
#include "EventManager.h"

//Object delegation
#include "Task.h"
#include "PropList.h"

//Thread Sync
#include <boost/thread/mutex.hpp>

#define LOG_DEBUG(String) Core::getSingletonPtr()->logDebug(String)
#define LOG_NORMAL(String) Core::getSingletonPtr()->logNormal(String)
#define LOG_CRITICAL(String) Core::getSingletonPtr()->logCritical(String)

using namespace std;
using namespace Ogre;

namespace Ymir {

    typedef struct {
        btCollisionShape* shape;
        btRigidBody* body;
        BtOgre::RigidBodyState* state;
    } RigidObjectInfo; 

    class RigidBodyState{

        public:
            RigidBodyState() : 
                shape(NULL), 
                body(NULL), 
                bodyState(NULL)
            {
            
            }
            
            ~RigidBodyState(){
            
                if( shape ){
                    delete shape;
                }

                if( body ){
                    delete body;
                }

                if( bodyState ){
                    delete bodyState;
                }
            }

            //Physics state
            btCollisionShape* shape;
            btRigidBody* body;
            BtOgre::RigidBodyState* bodyState;
    };

    class Core : public WindowEventListener 
    {
    
        public:

            ~Core();
    
            //Setup and tear down of ogre root
            int start(string title, string plugins, string config, string log);
            void stop();
   
            void logDebug( string msg ); 
            void logNormal( string msg );
            void logCritical( string msg );
    
            //Resource Management
            void addResourceLocation( string path, 
                                      string type, 
                                      string group, 
                                      bool recurse );
    
            void initialiseAllResourceGroups();
            //void initialiseMyGUI(std::string& config);

            void addEventListener(OgreEventListener* event);
    
            //Rendering support
            int ticktock();
            void resetTimer();

            //Object management
            void create( std::string& uuid, 
                         Ymir::Object::Type type, 
                         Ymir::PropList& props );

            void update( std::string& uuid, 
                         Ymir::Object::Type type,
                         Ymir::PropList& actions);

            void destroy( std::string& uuid,
                          Ymir::Object::Type type, 
                          Ymir::PropList& props ); 

            void windowClosed(RenderWindow* rw);
   
            Ogre::RaySceneQuery* createRayQuery(Ogre::Real x, Ogre::Real y);
            void destroyQuery( Ogre::SceneQuery* );

            static Ymir::Core* getSingletonPtr(); 

            friend class EventManager;

            friend class SceneBlueprint;

            friend class TerrainBlueprint;
        
            friend class CameraBlueprint;

            template<class T>
            friend class NodeBlueprint;

            template<class T>
            friend class MyGUIBlueprint;

            friend class AnimateEntityBlueprint;

        protected:
            Core();

            void setupInputDevices();
            void loadResources();

            boost::mutex mLock; 

            Ogre::Root* root;
            Ogre::Log* log;
            
            MyGUI::OgrePlatform* platform;
            MyGUI::Gui* gui;
            
            RenderWindow* window;
            bool rendering;
    
            EventManager* em;
            Ogre::Viewport* viewport;

            //Active Scene
            Ogre::SceneManager* mScene;
            CCS::CameraControlSystem* mCCS;

            //Terrain for active scene 
            Ogre::TerrainGlobalOptions* mTerrainGlobals;
            Ogre::TerrainGroup* mTerrainGroup;
            Ogre::TerrainPaging* mTerrainPaging;
            Ogre::PageManager* mPageManager;
            Ogre::PagedWorld* mWorld;
            
            //Physics for active scene
            btBroadphaseInterface* mBroadphase;
            btDefaultCollisionConfiguration* mCollisionConfig;
            btCollisionDispatcher* mCollisionDispatcher;
            btSequentialImpulseConstraintSolver* mConstraintSolver;
            BtOgre::DebugDrawer* mDebugDrawer;
            btDiscreteDynamicsWorld* mDynamicsWorld;

            std::map<std::string, RigidBodyState> mRigidObjects;

            static Core* core;
    };

    class CoreTask : public Task {

        typedef void (Ymir::Core::*CoreFP)();

        public:
        CoreTask( Ymir::Core* ptr, CoreFP fun ) : object(ptr), fp(fun) {}
        ~CoreTask(){}

        void run() { ((object)->*(fp))(); }

        protected:
            Ymir::Core* object;
            CoreFP fp;
    };

    /*class CoreObjectTask : public Task {

        typedef void (Ymir::Core::*CoreFP)( const std::string&, 
                                            Ymir::Object::Type type,
                                            Ymir::PropList& );

        public:
            CoreObjectTask( CoreFP fp, 
                            const std::string& id,
                            Ymir::Object::Type type = Ymir::Object::Invalid,
                            Ymir::PropList props = Ymir::PropList() ) : fp(fp), id(id), type(type), props(props) {}

            ~CoreObjectTask(){}

            void run() { 
                ((Ymir::Core::getSingletonPtr())->*(fp))(id, type, props);
            }

        protected:
            CoreFP fp; 
            std::string id;
            Ymir::Object::Type type;
            Ymir::PropList props;
            
    };*/
    /*class CoreObjectTask : public Task {
        typedef void (Ymir::Core::*CoreObjectFP) (Ymir::Object*);

        public: 
            CoreObjectTask( Ymir::Core* ptr, 
                            CoreObjectFP fun, 
                            Ymir::Object* obj ) : 
                instance(ptr), 
                fp(fun), 
                object(obj) 
            {       
        
            }

            ~CoreObjectTask(){}

            void run() { ((instance)->*(fp))(object); }

        protected:
            Ymir::Core* instance;
            CoreObjectFP fp;
            Ymir::Object* object;
    };*/
}

#endif
