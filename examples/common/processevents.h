/*
 * Copyright 2011-2013 Branimir Karadzic. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

#ifndef __PROCESS_EVENTS_H__
#define __PROCESS_EVENTS_H__

inline bool processEvents(uint32_t& _width, uint32_t& _height, uint32_t& _debug, uint32_t& _reset)
{
	using namespace entry;

	bool reset = false;

	const Event* ev;
	do
	{
		struct SE { const Event* m_ev; SE() : m_ev(poll() ) {} ~SE() { if (NULL != m_ev) { release(m_ev); } } } scopeEvent;
		ev = scopeEvent.m_ev;

		if (NULL != ev)
		{
			switch (ev->m_type)
			{
			case Event::Exit:
				return true;

			case Event::Mouse:
				{
// 					const MouseEvent* mouse = static_cast<const MouseEvent*>(ev);
// 					if (mouse->m_move)
// 					{
// 					}
				}
				break;

			case Event::Key:
				{
					const KeyEvent* key = static_cast<const KeyEvent*>(ev);
					if ( (key->m_key == Key::KeyQ && (key->m_modifiers & (Modifier::LeftCtrl|Modifier::RightCtrl) ) )
					|| ( (key->m_key == Key::Esc) ) )
					{
						return true;
					}
					else if (key->m_down)
					{
						if (key->m_key == Key::F1)
						{
							_debug ^= BGFX_DEBUG_STATS;
							bgfx::setDebug(_debug);
							return false;
						}
						else if (key->m_key == Key::F8)
						{
							_reset ^= BGFX_RESET_MSAA_X16;
							reset = true;
						}
						else if (key->m_key == Key::F9)
						{
							setWindowSize(640, 480);
							_width = 640;
							_height = 480;
						}
						else if (key->m_key == Key::F10)
						{
							setWindowSize(1280, 720);
							_width = 1280;
							_height = 720;
						}
						else if (key->m_key == Key::F11)
						{
							toggleWindowFrame();
						}
					}
				}
				break;

			case Event::Size:
				{
					const SizeEvent* size = static_cast<const SizeEvent*>(ev);
					_width = size->m_width;
					_height = size->m_height;
					reset = true;
				}
				break;

			default:
				break;
			}
		}
	} while (NULL != ev);

	if (reset)
	{
		bgfx::reset(_width, _height, _reset);
	}

	return false;
}

#endif // __PROCESS_EVENTS_H__
