package aerys.minko
{
	import aerys.common.Factory;
	import aerys.common.IVersionnable;
	import aerys.minko.ns.minko;
	import aerys.minko.query.IScene3DQuery;
	import aerys.minko.query.RenderingQuery;
	import aerys.minko.render.DirectRenderer3D;
	import aerys.minko.render.IRenderer3D;
	import aerys.minko.scene.IScene3D;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DRenderMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.getTimer;
	
	/**
	 *
	 * @author Jean-Marc Le Roux
	 *
	 */
	public class Viewport3D extends Sprite implements IVersionnable
	{
		use namespace minko;
		
		[Embed("../assets/minko_logo_app.png")]
		private static const ASSET_LOGO	: Class;
		
		private var _logo		: Sprite			= new Sprite();
		
		private var _width		: Number			= 0.;
		private var _height		: Number			= 0.;
		
		private var _version	: uint				= 0;
		
		private var _query		: RenderingQuery	= null;
		private var _time		: int				= 0;
		private var _sceneSize	: uint				= 0;
		private var _drawTime	: int				= 0;
		
		private var _renderer	: IRenderer3D		= null;
		private var _context	: Context3D			= null;
		
		private var _aa			: int				= 0;
		
		public function get version() : uint
		{
			return _version;
		}
		
		/**
		 * Indicates the width of the viewport.
		 * @return The width of the viewport.
		 *
		 */
		override public function get width()	: Number
		{
			return _width;
		}
		
		override public function set width(value : Number) : void
		{
			if (value != _width)
			{
				_width = value;
				++_version;
			}
		}
		
		public function get sceneSize() : uint
		{
			return _sceneSize;
		}
		
		/**
		 * Indicates the height of the viewport.
		 * @return The height of the viewport.
		 *
		 */
		override public function get height() : Number
		{
			return _height;
		}
		
		override public function set height(value : Number) : void
		{
			if (value != _height)
			{
				_height = value;
				++_version;
			}
		}
		
		public function get antiAliasing() : int
		{
			return _aa;
		}
		
		public function set antiAliasing(value : int) : void
		{
			if (value != _aa)
			{
				_aa = value;
				++_version;
				
				resetContext3D();
			}
		}
		
		public function get numTriangles() : uint
		{
			return _query ? _query.numTriangles
							: 0;
		}
		
		public function get renderingTime() : uint
		{
			return _time;
		}
		
		public function get drawingTime() : int
		{
			return _drawTime;
		}
		
		public function get renderMode() : String
		{
			if (_context)
				return _context.driverInfo.split(/^(\w+) Description=(.*) Driver=.*$/gs)[1];
			
			return null;
		}
		
		public function get driver() : String
		{
			if (_context)
				return _context.driverInfo.split(/^(\w+) Description=(.*) Driver=.*$/gs)[2];
			
			return null;
		}
		
		/**
		 * Creates a new Viewport object.
		 *
		 * @param width The width of the viewport.
		 * @param height The height of the viewport.
		 */
		public function Viewport3D(width		: Number,
								   height		: Number,
								   antiAliasing	: int	= 0)
		{
			this.width = width;
			this.height = height;
		
			_aa = antiAliasing;
			
			_logo.addChild(new ASSET_LOGO());
			_logo.addEventListener(MouseEvent.CLICK, logoClickHandler);
		}
		
		public static function setupOnStage(stage : Stage, antiAliasing : int = 0) : Viewport3D
		{
			var vp : Viewport3D = new Viewport3D(stage.stageWidth, stage.stageHeight, antiAliasing);
			
			vp.setupOnStage(stage);
			
			return vp;
		}
		
		private function setupOnStage(stage : Stage, autoResize : Boolean = true) : void
		{
			stage.addChild(this);
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, resetContext3D);
			stage.stage3Ds[0].viewPort = new Rectangle(0, 0, _width, _height);
			stage.stage3Ds[0].requestContext3D(Context3DRenderMode.AUTO);

			if (autoResize)
				stage.addEventListener(Event.RESIZE, stageResizeHandler);
		}
		
		private function stageResizeHandler(event : Event) : void
		{
			var stage : Stage = event.target as Stage;
			
			if (stage.stageWidth)
				width = stage.stageWidth;
			if (stage.stageHeight)
				height = stage.stageHeight;
			
			stage.stage3Ds[0].viewPort = new Rectangle(0, 0, _width, _height);
			
			resetContext3D();
		}
		
		private function resetContext3D(event : Event = null) : void
		{
			_context = stage.stage3Ds[0].context3D;
			_context.configureBackBuffer(_width, _height, _aa, true);
			_context.setDepthTest(true, Context3DCompareMode.LESS_EQUAL);
			
			_renderer = new DirectRenderer3D(this, _context);
			_query = new RenderingQuery(_renderer);
		}
		
		/**
		 * Render the specified scene.
		 * @param scene
		 */
		public function render(scene : IScene3D) : void
		{
			var time : int = getTimer();
			
			if (_context)
			{
				_query.reset();
				_query.query(scene);
				
				_renderer.present();
			}
			
			_time = getTimer() - time;
			_sceneSize = _query.numNodes;
			_drawTime = _query.drawingTime;

			Factory.sweep();
			
			showLogo();
		}	
	
		public function showLogo() : void
		{
			addChild(_logo);
		
			_logo.visible = true;
			_logo.useHandCursor = true;
			_logo.buttonMode = true;
			_logo.x = stage.stageWidth - _logo.width - 10;
			_logo.y = stage.stageHeight - _logo.height - 10;
		}
		
		private function logoClickHandler(event : Event) : void
		{
			navigateToURL(new URLRequest(Minko.URL), "_blank");
		}
	}
}