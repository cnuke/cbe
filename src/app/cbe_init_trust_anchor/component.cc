/*
 * Copyright (C) 2020 Genode Labs GmbH, Componolit GmbH, secunet AG
 *
 * This file is part of the Consistent Block Encrypter project, which is
 * distributed under the terms of the GNU Affero General Public License
 * version 3.
 */

/* Genode includes */
#include <base/attached_rom_dataspace.h>
#include <base/component.h>
#include <base/heap.h>
#include <block_session/connection.h>
#include <os/path.h>
#include <vfs/dir_file_system.h>
#include <vfs/file_system_factory.h>
#include <vfs/simple_env.h>

/* repo includes */
#include <util/io_job.h>


using namespace Genode;

class Main
{
	public:

		struct Missing_config_attribute : Genode::Exception { };

	private:

		Env   &_env;
		Heap  _heap { _env.ram(), _env.rm() };

		Attached_rom_dataspace _config_rom { _env, "config" };

		bool const _use_rom { _config_rom.xml().attribute_value("use_rom", false) };

		Constructible<Attached_rom_dataspace> _passphrase_rom { };

		Vfs::Simple_env   _vfs_env { _env, _heap, _config_rom.xml().sub_node("vfs") };
		Vfs::File_system &_vfs     { _vfs_env.root_dir() };

		using Passphrase = Genode::String<32 + 1>;
		Passphrase _passphrase { };

		struct Io_response_handler : Vfs::Io_response_handler
		{
			Genode::Signal_context_capability _io_sigh;

			Io_response_handler(Genode::Signal_context_capability io_sigh)
			: _io_sigh(io_sigh) { }

			void read_ready_response() override { }

			void io_progress_response() override
			{
				if (_io_sigh.valid()) {
					Genode::Signal_transmitter(_io_sigh).submit();
				}
			}
		};

		enum class State { WAIT, WRITE, READ, COMPLETE };
		State _state { State::WAIT };

		struct File
		{
			struct Could_not_open_file : Genode::Exception { };

			struct Completed
			{
				bool complete;
				bool success;
			};

			File(File const &) = delete;
			File &operator=(File const&) = delete;

			Vfs::File_system &_vfs;
			Vfs::Vfs_handle  *_vfs_handle;

			Io_response_handler &_io_response_handler;

			Genode::Constructible<Util::Io_job> _io_job { };
			Util::Io_job::Buffer                _io_buffer { };

			File(char          const *base_path,
				 char          const *name,
				 Vfs::File_system    &vfs,
				 Genode::Allocator   &alloc,
				 Io_response_handler &io_response_handler)
				:
					_vfs        { vfs },
					_vfs_handle { nullptr },
					_io_response_handler { io_response_handler }
			{
				using Result = Vfs::Directory_service::Open_result;

				Genode::Path<256> file_path = base_path;
				file_path.append_element(name);

				Result const res =
					_vfs.open(file_path.string(),
					          Vfs::Directory_service::OPEN_MODE_RDWR,
					          (Vfs::Vfs_handle **)&_vfs_handle, alloc);
				if (res != Result::OPEN_OK) {
					error("could not open '", file_path.string(), "'");
					throw Could_not_open_file();
				}

				_vfs_handle->handler(&io_response_handler);
			}

			~File()
			{
				_vfs.close(_vfs_handle);
			}

			void write_passphrase(Passphrase const &passphrase)
			{
				_io_buffer = {
					.base = const_cast<char *>(passphrase.string()),
					.size = passphrase.length()
				};

				_io_job.construct(*_vfs_handle, Util::Io_job::Operation::WRITE,
				                  _io_buffer, 0);
				
				_io_response_handler.io_progress_response();
			}

			void queue_read()
			{
				_io_buffer = {
					.base = nullptr,
					.size = 0,
				};

				_io_job.construct(*_vfs_handle, Util::Io_job::Operation::READ,
				                  _io_buffer, 0);
				
				_io_response_handler.io_progress_response();
			}

			void execute()
			{
				if (!_io_job.constructed()) {
					return;
				}

				_io_job->execute();
			}

			Completed write_complete()
			{
				return { _io_job->completed(), _io_job->succeeded() };
			}

			Completed read_complete()
			{
				return { _io_job->completed(), _io_job->succeeded() };
			}

			void drop_io_job()
			{
				_io_job.destruct();
			}
		};

		Genode::Constructible<File> _init_file { };

		Genode::Signal_handler<Main> _io_handler {
			_env.ep(), *this, &Main::_handle_io };

		void _handle_io()
		{
			_init_file->execute();

			File::Completed result { false, false };

			switch (_state) {
			case State::WAIT:
			{
				if (_use_rom) {
					_passphrase_rom->update();

					Xml_node const &node = _passphrase_rom->xml();

					_passphrase = node.attribute_value("passphrase", Passphrase());
					if (!_passphrase.valid()) {
						warning("could not obtain valid passphrase from ROM module");
						_env.parent().exit(1);
						break;
					}
				} else {
					_passphrase = _config_rom.xml().attribute_value("passphrase", Passphrase());
					if (!_passphrase.valid()) {
						warning("could not obtain valid passphrase from config");
						_env.parent().exit(1);
						break;
					}
				}

				_state = State::WRITE;
				_init_file->write_passphrase(_passphrase.string());
				break;
			}
			case State::WRITE:
				result = _init_file->write_complete();
				if (result.complete) {
					_init_file->drop_io_job();

					_state = State::READ;
					_init_file->queue_read();
				}
				break;
			case State::READ:
				result = _init_file->read_complete();
				if (result.complete) {
					_init_file->drop_io_job();
					_init_file.destruct();

					_state = State::COMPLETE;
					Genode::log("Initialization finished successfully");

					_env.parent().exit(result.success ? 0 : 1);
					return;
				}
				break;
			case State::COMPLETE:
				break;
			}
		}

		Io_response_handler _io_response_handler { _io_handler };

	public:

		Main(Env &env)
		:
			_env { env }
		{
			Xml_node const &config { _config_rom.xml() };

			bool const has_passphrase = config.has_attribute("passphrase");
			if (!has_passphrase && !_use_rom) {
				error("passphrase missing");
				throw Missing_config_attribute();
			}

			using String_path = Genode::String<256>;
			String_path const ta_dir =
				config.attribute_value("trust_anchor_dir", String_path());
			if (!ta_dir.valid()) {
				error("missing mandatory 'trust_anchor_dir' config attribute");
				throw Missing_config_attribute();
			}

			_init_file.construct(ta_dir.string(), "initialize",
			                     _vfs, _vfs_env.alloc(),
			                     _io_response_handler);

			/* using a ROM module takes precedence */
			if (_use_rom) {
				_passphrase_rom.construct(_env, "passphrase");
			}

			/* kick-off */
			_handle_io();
		}
};


void Component::construct(Genode::Env &env)
{
	static Main main(env);
}
